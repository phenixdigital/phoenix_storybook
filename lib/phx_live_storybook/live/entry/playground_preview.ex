defmodule PhxLiveStorybook.Entry.PlaygroundPreview do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.ComponentRenderer

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class="lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lsb-mb-4 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-px-2 lsb-py-8 lsb-bg-white lsb-shadow-sm lsb-justify-evenly">
      <%= ComponentRenderer.render_component("playground-preview", fun_or_component(@entry), @attrs, nil, nil) %>
    </div>
    """
  end

  defp fun_or_component(%ComponentEntry{type: :live_component, component: component}),
    do: component

  defp fun_or_component(%ComponentEntry{type: :component, function: function}),
    do: function
end
