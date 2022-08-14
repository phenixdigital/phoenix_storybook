defmodule AComponent do
  use Phoenix.Component

  def a_component(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:index, fn -> 42 end)

    ~H"<span data-index={@index}>a component: <%= @label %></span>"
  end
end
