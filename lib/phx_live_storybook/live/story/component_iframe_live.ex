defmodule PhxLiveStorybook.Story.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.Story.PlaygroundPreviewLive
  alias PhxLiveStorybook.StoryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"],
       assets_path: session["assets_path"]
     ), layout: {PhxLiveStorybook.LayoutView, "live_iframe.html"}}
  end

  def handle_params(params = %{"story" => story_path}, _uri, socket) do
    case load_story(socket, story_path) do
      nil ->
        raise StoryNotFound, "unknown story #{inspect(story_path)}"

      story ->
        {:noreply,
         assign(socket,
           playground: params["playground"],
           story_path: story_path,
           story: story,
           variation_id: parse_atom(params["variation_id"]),
           topic: params["topic"],
           theme: parse_atom(params["theme"]),
           extra_assigns: %{}
         )}
    end
  end

  defp load_story(socket, story_param) do
    story_storybook_path = "/#{Enum.join(story_param, "/")}"
    socket.assigns.backend_module.find_story_by_path(story_storybook_path)
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(atom_s), do: String.to_atom(atom_s)

  def render(assigns) do
    assigns =
      assign(assigns, component_assigns: Map.merge(%{theme: assigns.theme}, assigns.extra_assigns))

    ~H"""
    <%= if @variation_id do %>
      <%= if @playground do %>
        <%= live_render @socket, PlaygroundPreviewLive,
          id: playground_preview_id(@story),
          session: %{"story_path" => @story_path, "variation_id" => @variation_id,
          "backend_module" => to_string(@backend_module), "theme" => @theme,
          "topic" => @topic},
          container: {:div, style: "height: 100vh; width: 100wh;"}
        %>
      <% else %>
        <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px;">
          <%= @backend_module.render_variation(@story.module(), @variation_id, @component_assigns) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp playground_preview_id(story) do
    module = story.module |> Macro.underscore() |> String.replace("/", "_")
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
end
