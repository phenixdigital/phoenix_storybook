defmodule NestedComponent do
  use Phoenix.Component

  def nested_component(assigns) do
    ~H"""
    <div>
      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def nested(assigns) do
    assigns = assign_new(assigns, :label, fn -> "" end)

    ~H"""
    <span>I'm nested: <%= @label %></span>
    """
  end

  def other_nested(assigns), do: nested(assigns)
end
