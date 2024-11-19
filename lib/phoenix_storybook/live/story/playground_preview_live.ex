defmodule PhoenixStorybook.Story.PlaygroundPreviewLive do
  @moduledoc false
  use PhoenixStorybook.Web, :live_view

  alias Phoenix.PubSub
  alias PhoenixStorybook.ExtraAssignsHelpers
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.Rendering.{ComponentRenderer, RenderingContext}
  alias PhoenixStorybook.Stories.{Variation, VariationGroup}
  alias PhoenixStorybook.ThemeHelpers

  def mount(_params, session, socket) do
    story = session["story"]

    if connected?(socket) && session["topic"] do
      PubSub.subscribe(PhoenixStorybook.PubSub, session["topic"])

      PubSub.broadcast!(
        PhoenixStorybook.PubSub,
        session["topic"],
        {:playground_preview_pid, self()}
      )
    end

    variation_or_group =
      Enum.find(story.variations(), &(to_string(&1.id) == session["variation_id"]))

    ThemeHelpers.call_theme_function(session["backend_module"], session["theme"])

    {:ok,
     socket
     |> assign(
       story: story,
       topic: session["topic"],
       theme: session["theme"],
       color_mode: session["color_mode"],
       backend_module: session["backend_module"]
     )
     |> assign_color_mode_class()
     |> assign_variations_attributes(variation_or_group), layout: false}
  end

  defp assign_color_mode_class(socket = %{assigns: assigns}) do
    class =
      if assigns.color_mode == "dark" do
        assigns.backend_module.config(:color_mode_sandbox_dark_class, "dark")
      end

    assign(socket, :color_mode_class, class)
  end

  defp assign_variations_attributes(socket, variation_or_group) do
    case variation_or_group do
      variation = %Variation{} ->
        assign_variations_attributes(socket, variation, [variation])

      group = %VariationGroup{variations: vars} ->
        assign_variations_attributes(socket, group, vars)

      _ ->
        assign_variations_attributes(socket, nil, [])
    end
  end

  defp assign_variations_attributes(socket, variation_or_group, variations) do
    assign(
      socket,
      counter: 0,
      variation: variation_or_group,
      variation_id: if(variation_or_group, do: variation_or_group.id, else: nil),
      variations_attributes:
        for variation <- variations, into: %{} do
          {variation_id(variation_or_group, variation.id),
           Map.put(
             variation.attributes,
             :theme,
             theme(socket.assigns.theme)
           )}
        end
    )
  end

  defp variation_id(%VariationGroup{id: group_id}, variation_id), do: {group_id, variation_id}
  defp variation_id(%Variation{}, variation_id), do: {:single, variation_id}

  defp theme(theme) when is_binary(theme), do: String.to_atom(theme)
  defp theme(theme) when is_atom(theme), do: theme

  def render(assigns = %{variation: nil}), do: ~H""

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :context,
        RenderingContext.build(
          assigns.backend_module,
          assigns.story,
          assigns.variation,
          assigns.variations_attributes,
          playground_topic: assigns.topic,
          imports: [{__MODULE__, psb_inspect: 4}]
        )
      )

    ~H"""
    <div id="playground-preview-live" style="width: 100%; height: 100%;">
      <div
        id={"sandbox-#{@counter}"}
        class={[
          LayoutView.sandbox_class(
            @socket,
            LayoutView.normalize_story_container(@story.container()),
            assigns
          ),
          @color_mode_class
        ]}
        ,
        style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; height: 100%; width: 100%; padding: 10px;"
      >
        <%= ComponentRenderer.render(@context) %>
      </div>
    </div>
    """
  end

  # Attributes passed in templates (as <.psb-variation .../> tag attributes) carry a value only
  # known at runtime.
  # Template will call `psb_inspect/4` for each of these attributes, in order to let the Playground
  # know their current value.
  def psb_inspect(playground_topic, variation_id, key, val) do
    PubSub.broadcast!(
      PhoenixStorybook.PubSub,
      playground_topic,
      {:new_template_attributes, %{variation_id => %{key => val}}}
    )

    val
  end

  def handle_info({:new_attributes_input, new_attrs}, socket) do
    variation_attributes =
      for {variation_id, attributes} <- socket.assigns.variations_attributes, into: %{} do
        {variation_id,
         attributes |> Map.merge(new_attrs) |> Map.reject(fn {_, v} -> is_nil(v) end)}
      end

    {:noreply, socket |> inc_counter() |> assign(variations_attributes: variation_attributes)}
  end

  def handle_info({:set_theme, theme}, socket) do
    variation_attributes =
      for {variation_id, attributes} <- socket.assigns.variations_attributes, into: %{} do
        {variation_id, Map.put(attributes, :theme, theme)}
      end

    {:noreply,
     socket
     |> inc_counter()
     |> assign(theme: theme)
     |> assign(variations_attributes: variation_attributes)}
  end

  def handle_info({:set_color_mode, color_mode}, socket) do
    {:noreply,
     socket
     |> inc_counter()
     |> assign(color_mode: color_mode)
     |> assign_color_mode_class()}
  end

  def handle_info({:set_variation, variation}, socket) do
    {:noreply, assign_variations_attributes(socket, variation)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def handle_event("psb-assign", assign_params, socket = %{assigns: assigns}) do
    variation_attributes =
      for {variation_id, attributes} <- assigns.variations_attributes, into: %{} do
        {new_variation_id, new_attributes} =
          ExtraAssignsHelpers.handle_set_variation_assign(
            assign_params,
            assigns.variations_attributes,
            assigns.story
          )

        if new_variation_id == variation_id do
          {variation_id, new_attributes}
        else
          {variation_id, attributes}
        end
      end

    send_variations_attributes(assigns.topic, variation_attributes)
    {:noreply, socket |> inc_counter() |> assign(variations_attributes: variation_attributes)}
  end

  def handle_event("psb-toggle", assign_params, socket = %{assigns: assigns}) do
    variation_attributes =
      for {variation_id, attributes} <- assigns.variations_attributes, into: %{} do
        {new_variation_id, new_attributes} =
          ExtraAssignsHelpers.handle_toggle_variation_assign(
            assign_params,
            assigns.variations_attributes,
            assigns.story
          )

        if new_variation_id == variation_id do
          {variation_id, new_attributes}
        else
          {variation_id, attributes}
        end
      end

    send_variations_attributes(assigns.topic, variation_attributes)
    {:noreply, socket |> inc_counter() |> assign(variations_attributes: variation_attributes)}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  defp send_variations_attributes(topic, variation_attributes) do
    PubSub.broadcast!(
      PhoenixStorybook.PubSub,
      topic,
      {:new_variations_attributes, variation_attributes}
    )
  end

  # Some components outside of the liveview world needs an ID update to re-render.
  # It's the case for FontAwesome JS.
  defp inc_counter(socket) do
    assign(socket, :counter, socket.assigns.counter + 1)
  end
end
