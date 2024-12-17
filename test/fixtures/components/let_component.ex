defmodule LetComponent do
  use Phoenix.Component

  attr :stories, :list, doc: "list of stories"

  slot :my_slot,
    doc: """
    slot documentation

    is working multine
    """ do
    attr :optional_attr, :string, doc: "Optional attr"
  end

  def let_component(assigns) do
    ~H"""
    <ul>
      <%= for story <- @stories do %>
        <li>
          <%= render_slot(@my_slot, story) %>
        </li>
      <% end %>
    </ul>
    """
  end
end
