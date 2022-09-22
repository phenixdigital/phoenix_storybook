defmodule PhxLiveStorybook.Story.PlaygroundPreviewLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.Rendering.ComponentRenderer
  alias PhxLiveStorybook.TemplateHelpers
  alias PhxLiveStorybook.{Variation, VariationGroup}

  def mount(_params, session, socket) do
    story = session["story"]

    if connected?(socket) && session["topic"] do
      PubSub.subscribe(PhxLiveStorybook.PubSub, session["topic"])

      PubSub.broadcast!(
        PhxLiveStorybook.PubSub,
        session["topic"],
        {:playground_preview_pid, self()}
      )
    end

    variation_or_group =
      Enum.find(story.variations(), &(to_string(&1.id) == session["variation_id"]))

    {:ok,
     socket
     |> assign(story: story, topic: session["topic"], theme: session["theme"])
     |> assign_variations(variation_or_group), layout: false}
  end

  defp assign_variations(socket, variation_or_group) do
    case variation_or_group do
      variation = %Variation{} ->
        assign_variations(socket, variation, [variation])

      group = %VariationGroup{variations: variations} ->
        assign_variations(socket, group, variations)

      _ ->
        assign_variations(socket, nil, [])
    end
  end

  defp assign_variations(socket, variation_or_group, variations) do
    assign(
      socket,
      counter: 0,
      variation: variation_or_group,
      variation_id: if(variation_or_group, do: variation_or_group.id, else: nil),
      variations:
        for variation <- variations do
          %{
            id: variation.id,
            let: variation.let,
            block: variation.block,
            slots: variation.slots,
            attributes:
              Map.merge(
                %{id: "playground-preview-#{variation.id}", theme: socket.assigns.theme},
                variation.attributes
              )
          }
        end
    )
  end

  def render(assigns) do
    template = TemplateHelpers.get_template(assigns.story.template, assigns.variation)

    opts = [
      playground_topic: assigns.topic,
      imports: [{__MODULE__, lsb_inspect: 4} | assigns.story.imports],
      aliases: assigns.story.aliases
    ]

    ~H"""
    <div id="playground-preview-live" style="width: 100%; height: 100%;">
      <div id={"sandbox-#{@counter}"} class={LayoutView.sandbox_class(assigns)} style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; height: 100%; width: 100%; padding: 10px;">
        <%= ComponentRenderer.render_multiple_variations(fun_or_component(@story), @variation, @variations, template, opts) %>
      </div>
    </div>
    """
  end

  # Attributes passed in templates (as <.lsb-variation .../> tag attributes) carry a value only
  # known at runtime.
  # Template will call `lsb_inspect/4` for each of these attributes, in order to let the Playground
  # know their current value.
  def lsb_inspect(playground_topic, variation_id, key, val) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      playground_topic,
      {:new_template_attributes, %{variation_id => %{key => val}}}
    )

    val
  end

  defp fun_or_component(story) do
    case story.storybook_type() do
      :component -> story.function()
      :live_component -> story.component()
    end
  end

  def handle_info({:new_attributes_input, attrs}, socket) do
    variations =
      for variation <- socket.assigns.variations do
        new_attrs =
          variation.attributes |> Map.merge(attrs) |> Map.reject(fn {_, v} -> is_nil(v) end)

        %{variation | attributes: new_attrs}
      end

    {:noreply, socket |> inc_counter() |> assign(variations: variations)}
  end

  def handle_info({:set_theme, theme}, socket) do
    {:noreply,
     socket
     |> assign(:theme, theme)
     |> assign_variations(socket.assigns.variation)}
  end

  def handle_info({:set_variation, variation}, socket) do
    {:noreply, assign_variations(socket, variation)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def handle_event("assign", assign_params, socket = %{assigns: assigns}) do
    variations =
      for variation <- assigns.variations do
        {variation_id, attrs} =
          ExtraAssignsHelpers.handle_set_variation_assign(
            assign_params,
            variation.attributes,
            assigns.story,
            :flat
          )

        if variation.id == variation_id do
          %{variation | attributes: attrs}
        else
          variation
        end
      end

    send_variations_attributes(assigns.topic, variations)
    {:noreply, socket |> inc_counter() |> assign(variations: variations)}
  end

  def handle_event("toggle", assign_params, socket = %{assigns: assigns}) do
    variations =
      for variation <- assigns.variations do
        {variation_id, attrs} =
          ExtraAssignsHelpers.handle_toggle_variation_assign(
            assign_params,
            variation.attributes,
            assigns.story,
            :flat
          )

        if variation.id == variation_id do
          %{variation | attributes: attrs}
        else
          variation
        end
      end

    send_variations_attributes(assigns.topic, variations)
    {:noreply, socket |> inc_counter() |> assign(variations: variations)}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  defp send_variations_attributes(topic, variations) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      topic,
      {:new_variations_attributes, variations |> Enum.map(&{&1.id, &1.attributes}) |> Map.new()}
    )
  end

  # Some components outside of the liveview world needs an ID update to re-render.
  # It's the case for FontAwesome JS.
  defp inc_counter(socket) do
    assign(socket, :counter, socket.assigns.counter + 1)
  end
end
