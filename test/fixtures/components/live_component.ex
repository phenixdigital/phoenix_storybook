defmodule LiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <span>
      b component: <%= @label %>
      <%= if assigns[:inner_block] do %>
        <%= render_block(@inner_block) %>
      <% end %>
    </span>
    """
  end
end
