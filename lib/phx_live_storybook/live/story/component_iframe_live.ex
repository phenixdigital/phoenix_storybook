defmodule PhxLiveStorybook.Story.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.Rendering.{ComponentRenderer, RenderingContext}
  alias PhxLiveStorybook.Story.PlaygroundPreviewLive
  alias PhxLiveStorybook.Stories.{Variation, VariationGroup}
  alias PhxLiveStorybook.StoryNotFound
  alias PhxLiveStorybook.ThemeHelpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, []), layout: {PhxLiveStorybook.LayoutView, :live_iframe}}
  end

  def handle_params(params = %{"story" => story_path}, _uri, socket) do
    case load_story(socket, story_path) do
      {:ok, story} ->
        if params["topic"] do
          PubSub.broadcast!(
            PhxLiveStorybook.PubSub,
            params["topic"],
            {:component_iframe_pid, self()}
          )
        end

        ThemeHelpers.call_theme_function(socket.assigns.backend_module, params["theme"])

        {:noreply,
         socket
         |> assign(
           playground: params["playground"],
           story_path: story_path,
           story: story,
           variation_id: params["variation_id"],
           variation: current_variation(story.storybook_type(), story, params),
           topic: params["topic"],
           theme: params["theme"]
         )
         |> assign_extra_assigns()}

      {:error, _error, exception} ->
        raise exception

      {:error, :not_found} ->
        raise StoryNotFound, "unknown story #{inspect(story_path)}"
    end
  end

  defp load_story(socket, story_param) do
    story_path = Path.join(story_param)
    socket.assigns.backend_module.load_story(story_path)
  end

  defp assign_extra_assigns(socket) do
    case Map.get(socket.assigns, :variation) do
      nil ->
        assign(socket, :extra_assigns, %{})

      %Variation{id: id} ->
        assign(socket, :extra_assigns, %{{:single, id} => %{}})

      %VariationGroup{id: group_id, variations: variations} ->
        assign(
          socket,
          :extra_assigns,
          for(%Variation{id: id} <- variations, into: %{}, do: {{group_id, id}, %{}})
        )
    end
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :context,
        RenderingContext.build(
          assigns.story,
          assigns.variation,
          variation_extra_attributes(assigns.variation, assigns)
        )
      )

    ~H"""
    <%= if @variation_id do %>
      <%= if @playground do %>
        <%= live_render @socket, PlaygroundPreviewLive,
          id: playground_preview_id(@story),
          session: %{
            "story" => @story,
            "variation_id" => @variation_id,
            "theme" => @theme,
            "topic" => @topic,
            "backend_module" => @backend_module
            },
          container: {:div, style: "height: 100vh; width: 100wh;"}
        %>
      <% else %>
        <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px;">
          <%= ComponentRenderer.render(@context) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp playground_preview_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  defp current_variation(type, story, %{"variation_id" => variation_id})
       when type in [:component, :live_component] do
    Enum.find(story.variations(), &(to_string(&1.id) == variation_id))
  end

  defp current_variation(type, story, _) when type in [:component, :live_component] do
    case story.variations() do
      [variation | _] -> variation
      _ -> nil
    end
  end

  defp current_variation(_type, _story, _params), do: nil

  defp variation_extra_attributes(%Variation{id: variation_id}, assigns) do
    extra_assigns = Map.get(assigns.extra_assigns, {:single, variation_id}, %{})

    extra_assigns =
      case ThemeHelpers.theme_assign(assigns.backend_module, assigns.theme) do
        {assign_key, theme} -> Map.put(extra_assigns, assign_key, theme)
        nil -> extra_assigns
      end

    %{variation_id => extra_assigns}
  end

  defp variation_extra_attributes(%VariationGroup{id: group_id}, assigns) do
    maybe_theme_assign = ThemeHelpers.theme_assign(assigns.backend_module, assigns.theme)

    for {{^group_id, variation_id}, extra_assigns} <- assigns.extra_assigns,
        into: %{} do
      case maybe_theme_assign do
        {assign_key, theme} -> {variation_id, Map.put(extra_assigns, assign_key, theme)}
        _ -> {variation_id, extra_assigns}
      end
    end
  end

  def handle_event("assign", assign_params, socket = %{assigns: assigns}) do
    {variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_set_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply, assign(socket, extra_assigns: %{variation_id => extra_assigns})}
  end

  def handle_event("toggle", assign_params, socket = %{assigns: assigns}) do
    {variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply, assign(socket, extra_assigns: %{variation_id => extra_assigns})}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}
end
