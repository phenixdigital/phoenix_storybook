defmodule PhxLiveStorybook.Story.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.Rendering.{ComponentRenderer, RenderingContext}
  alias PhxLiveStorybook.Story.PlaygroundPreviewLive
  alias PhxLiveStorybook.Stories.{Variation, VariationGroup}
  alias PhxLiveStorybook.StoryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       backend_module: session["backend_module"],
       assets_path: session["assets_path"]
     ), layout: {PhxLiveStorybook.LayoutView, "live_iframe.html"}}
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

        {:noreply,
         assign(socket,
           playground: params["playground"],
           story_path: story_path,
           story: story,
           variation_id: params["variation_id"],
           variation: current_variation(story.storybook_type(), story, params),
           topic: params["topic"],
           theme: params["theme"],
           extra_assigns: %{}
         )}

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
    extra_assigns =
      assigns.extra_assigns
      |> Map.get({:single, variation_id}, %{})
      |> Map.put(:theme, assigns.theme)

    %{variation_id => extra_assigns}
  end

  defp variation_extra_attributes(%VariationGroup{id: group_id}, assigns) do
    for {{^group_id, variation_id}, extra_assigns} <- assigns.extra_assigns,
        into: %{} do
      {variation_id, Map.merge(extra_assigns, %{theme: assigns.theme})}
    end
  end

  def handle_event("assign", assign_params, socket = %{assigns: assigns}) do
    {_variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_set_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end

  def handle_event("toggle", assign_params, socket = %{assigns: assigns}) do
    {_variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}
end
