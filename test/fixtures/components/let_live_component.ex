defmodule LetLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
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
