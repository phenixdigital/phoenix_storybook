defmodule LetLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
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
