defmodule PhxLiveStorybook.Entry.PlaygroundPreviewLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.ComponentRenderer

  def mount(_params, session, socket) do
    entry = load_entry(String.to_atom(session["backend_module"]), session["entry_path"])

    if connected?(socket) do
      PubSub.subscribe(PhxLiveStorybook.PubSub, "playground")
      PubSub.broadcast!(PhxLiveStorybook.PubSub, "playground", {:playground_preview_pid, self()})
    end

    story =
      Enum.find(
        entry.stories,
        %{attributes: %{}, block: nil, slots: nil},
        &(&1.id == session["story_id"])
      )

    {:ok,
     assign(socket,
       entry: entry,
       attrs: story.attributes,
       block: story.block,
       slots: story.slots,
       parent_pid: session["parent_pid"],
       sequence: 0
     ), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div id={"playground-preview-live-#{@sequence}"} style="height: 100%;">
      <div class="lsb lsb-sandbox" style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; height: 100%;">
        <%= ComponentRenderer.render_component("playground-preview", fun_or_component(@entry), @attrs, @block, @slots) %>
      </div>
    </div>
    """
  end

  defp load_entry(backend_module, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp fun_or_component(%ComponentEntry{type: :live_component, component: component}),
    do: component

  defp fun_or_component(%ComponentEntry{type: :component, function: function}),
    do: function

  def handle_info({:new_attributes, pid, attrs}, socket = %{assigns: assigns})
      when pid == assigns.parent_pid do
    {:noreply, assign(socket, attrs: attrs, sequence: socket.assigns.sequence + 1)}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
