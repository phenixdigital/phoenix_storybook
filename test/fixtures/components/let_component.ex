defmodule LetComponent do
  use Phoenix.Component

  attr :stories, :list, doc: "list of stories"

  slot :inner_block,
    doc: """
    slot documentation

    is working multine
    """

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
