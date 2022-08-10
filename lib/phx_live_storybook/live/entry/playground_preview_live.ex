defmodule PhxLiveStorybook.Entry.PlaygroundPreviewLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.ComponentRenderer

  def mount(_params, session, socket) do
    if socket.parent_pid do
      send(socket.parent_pid, {:playground_preview_pid, self()})
    end

    entry = load_entry(String.to_atom(session["backend_module"]), session["entry_path"])
    story = Enum.find(entry.stories, %{attributes: %{}}, &(&1.id == session["story_id"]))

    {:ok,
     assign(socket,
       entry: entry,
       attrs: story.attributes,
       block: story.block,
       slots: story.slots,
       sequence: 0,
       show_class: ""
     )}
  end

  def render(assigns) do
    ~H"""
    <div id={"playground-preview-live-#{@sequence}"} class={"#{@show_class} lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-px-2 lsb-min-h-32 lsb-bg-white lsb-shadow-sm lsb-justify-evenly"}>
      <%= if assigns[:entry] do %>
        <%= ComponentRenderer.render_component("playground-preview", fun_or_component(@entry), @attrs, @block, @slots) %>
      <% end %>
    </div>
    """
  end

  defp load_entry(backend_module, entry_param) do
    entry_absolute_path = "/#{Enum.join(entry_param, "/")}"
    backend_module.find_entry_by_path(entry_absolute_path)
  end

  defp fun_or_component(%ComponentEntry{type: :live_component, component: component}),
    do: component

  defp fun_or_component(%ComponentEntry{type: :component, function: function}),
    do: function

  def handle_info({:new_attrs, attrs}, socket) do
    {:noreply, assign(socket, attrs: attrs, sequence: socket.assigns.sequence + 1)}
  end

  def handle_info(:hide, socket) do
    {:noreply, assign(socket, show_class: "lsb-hidden")}
  end

  def handle_info(:show, socket) do
    {:noreply, assign(socket, show_class: "")}
  end
end
