defmodule BComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <span>
      b component: <%= @label %>
      <%= if assigns[:block] do %>
        <%= @block %>
      <% end %>
    </span>
    """
  end
end
