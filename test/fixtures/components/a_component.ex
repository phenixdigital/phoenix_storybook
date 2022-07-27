defmodule AComponent do
  use Phoenix.Component

  def a_component(assigns) do
    assigns = assign_new(assigns, :index, fn -> 42 end)
    ~H"<span data-index={@index}>a component: <%= @label %></span>"
  end
end
