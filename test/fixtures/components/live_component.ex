defmodule LiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <span>
      b component: <%= @label %>
      <%= render_block(@inner_block) %>
    </span>
    """
  end
end
