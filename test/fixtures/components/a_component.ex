defmodule AComponent do
  use Phoenix.Component

  def a_component(assigns) do
    ~H"<span>a component: <%= @label %></span>"
  end
end
