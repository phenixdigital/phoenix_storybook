defmodule PhxLiveStorybook.ComponentIframeLive do
  use Phoenix.LiveView, container: {:div, style: "height: 100%;"}

  alias PhxLiveStorybook.Entry.PlaygroundPreviewLive
  alias PhxLiveStorybook.EntryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"]
     ), layout: {PhxLiveStorybook.LayoutView, "live_iframe.html"}}
  end

  def handle_params(params = %{"entry" => entry_path, "story_id" => story_id}, _uri, socket) do
    case load_entry(socket, entry_path) do
      nil ->
        raise EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry ->
        {:noreply,
         assign(socket,
           playground: params["playground"],
           entry_path: entry_path,
           entry: entry,
           story_id: String.to_atom(story_id),
           parent_pid: parse_pid(params["parent_pid"])
         )}
    end
  end

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp parse_pid(nil), do: nil

  defp parse_pid(pid) do
    [_, a, b, c, _] = String.split(pid, ["<", ".", ">"])
    :c.pid(String.to_integer(a), String.to_integer(b), String.to_integer(c))
  end

  def render(assigns) do
    ~H"""
    <%= if @playground do %>
      <%= live_render @socket, PlaygroundPreviewLive,
        id: playground_preview_id(@entry),
        session: %{"entry_path" => @entry_path, "story_id" => @story_id, "backend_module" => to_string(@backend_module), "parent_pid" => @parent_pid}
      %>
    <% else %>
      <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
        <%= @backend_module.render_story(@entry.module, @story_id) %>
      </div>
    <% end %>
    """
  end

  defp playground_preview_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end
end
