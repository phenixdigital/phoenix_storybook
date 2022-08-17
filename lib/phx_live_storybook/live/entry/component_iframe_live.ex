defmodule PhxLiveStorybook.ComponentIframeLive do
  use Phoenix.LiveView, container: {:div, style: "height: 100%;"}

  alias PhxLiveStorybook.EntryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"]
     ), layout: {PhxLiveStorybook.LayoutView, "live_iframe.html"}}
  end

  def handle_params(_params = %{"entry" => entry_path, "story_id" => story_id}, _uri, socket) do
    case load_entry(socket, entry_path) do
      nil -> raise EntryNotFound, "unknown entry #{inspect(entry_path)}"
      entry -> {:noreply, assign(socket, entry: entry, story_id: String.to_atom(story_id))}
    end
  end

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  def render(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
      <%= @backend_module.render_story(@entry.module, @story_id) %>
    </div>
    """
  end
end
