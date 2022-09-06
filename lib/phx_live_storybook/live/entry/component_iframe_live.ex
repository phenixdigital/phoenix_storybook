defmodule PhxLiveStorybook.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias PhxLiveStorybook.Entry.PlaygroundPreviewLive
  alias PhxLiveStorybook.EntryNotFound
  alias PhxLiveStorybook.ExtraAssignsHelpers

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"],
       assets_path: session["assets_path"]
     ), layout: {PhxLiveStorybook.LayoutView, "live_iframe.html"}}
  end

  def handle_params(params = %{"entry" => entry_path}, _uri, socket) do
    case load_entry(socket, entry_path) do
      nil ->
        raise EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry ->
        {:noreply,
         assign(socket,
           playground: params["playground"],
           entry_path: entry_path,
           entry: entry,
           story_id: parse_atom(params["story_id"]),
           topic: params["topic"],
           theme: parse_atom(params["theme"]),
           extra_assigns: %{}
         )}
    end
  end

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(atom_s), do: String.to_atom(atom_s)

  def render(assigns) do
    assigns =
      assign(assigns, component_assigns: Map.merge(%{theme: assigns.theme}, assigns.extra_assigns))

    ~H"""
    <%= if @story_id do %>
      <%= if @playground do %>
        <%= live_render @socket, PlaygroundPreviewLive,
          id: playground_preview_id(@entry),
          session: %{"entry_path" => @entry_path, "story_id" => @story_id,
          "backend_module" => to_string(@backend_module), "theme" => @theme,
          "topic" => @topic},
          container: {:div, style: "height: 100vh;"}
        %>
      <% else %>
        <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px;">
          <%= @backend_module.render_story(@entry.module(), @story_id, @component_assigns) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp playground_preview_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  def handle_event("set-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {_story_id, extra_assigns} =
      ExtraAssignsHelpers.handle_set_story_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.entry,
        :flat
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end

  def handle_event("toggle-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {_story_id, extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_story_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.entry,
        :flat
      )

    {:noreply, assign(socket, extra_assigns: extra_assigns)}
  end
end
