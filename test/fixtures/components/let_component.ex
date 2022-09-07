defmodule LetComponent do
  use Phoenix.Component

  def let_component(assigns) do
    ~H"""
    <ul>
      <%= for entry <- @entries do %>
        <li>
          <%= render_slot(@inner_block, entry) %>
        </li>
      <% end %>
    </ul>
    """
  end
end
