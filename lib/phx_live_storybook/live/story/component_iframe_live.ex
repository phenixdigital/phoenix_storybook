defmodule PhxLiveStorybook.Story.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.Rendering.ComponentRenderer
  alias PhxLiveStorybook.Story.PlaygroundPreviewLive
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
      assign(assigns, component_assigns: Map.merge(%{theme: assigns.theme}, assigns.extra_assigns))

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
          <%= ComponentRenderer.render_variation(@story, @variation_id, @component_assigns) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp playground_preview_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  def handle_event("assign", assign_params, socket = %{assigns: assigns}) do
    {_variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_set_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story,
        :flat
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end

  def handle_event("toggle", assign_params, socket = %{assigns: assigns}) do
    {_variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story,
        :flat
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}
end
