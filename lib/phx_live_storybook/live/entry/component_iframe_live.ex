defmodule PhxLiveStorybook.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias PhxLiveStorybook.Entry.PlaygroundPreviewLive
  alias PhxLiveStorybook.EntryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"]
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
           story_id: parse_story_id(params["story_id"]),
           parent_pid: parse_pid(params["parent_pid"]),
           theme: parse_theme(params["theme"])
         )}
    end
  end

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp parse_story_id(nil), do: nil

  defp parse_story_id(story_id) do
    ids =
      story_id
      |> String.split(~w([ , : ]))
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.to_atom/1)

    case ids do
      [story_id] -> story_id
      [_group_id, _story_id] -> ids
    end
  end

  defp parse_pid(nil), do: nil

  defp parse_pid(pid) do
    [_, a, b, c, _] = String.split(pid, ["<", ".", ">"])
    :c.pid(String.to_integer(a), String.to_integer(b), String.to_integer(c))
  end

  defp parse_theme(nil), do: nil
  defp parse_theme(""), do: nil
  defp parse_theme(theme), do: String.to_atom(theme)

  def render(assigns) do
    ~H"""
    <%= if @story_id do %>
      <%= if @playground do %>
        <%= live_render @socket, PlaygroundPreviewLive,
          id: playground_preview_id(@entry),
          session: %{"entry_path" => @entry_path, "story_id" => @story_id, "backend_module" => to_string(@backend_module), "theme" => @theme, "parent_pid" => @parent_pid},
          container: {:div, style: "height: 100vh;"}
        %>
      <% else %>
        <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px;">
          <%= @backend_module.render_story(@entry.module(), @story_id, %{theme: @theme}) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp playground_preview_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end
end
