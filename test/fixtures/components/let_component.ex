defmodule LetComponent do
  use Phoenix.Component

  def let_component(assigns) do
    ~H"""
    <ul>
      <%= for story <- @stories do %>
        <li>
          <%= render_slot(@inner_block, story) %>
        </li>
      <% end %>
    </ul>
    """
  end
end
