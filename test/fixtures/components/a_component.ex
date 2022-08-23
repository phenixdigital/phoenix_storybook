defmodule AComponent do
  use Phoenix.Component

  def a_component(assigns) do
    assigns =
      assigns
      |> assign_new(:theme, fn -> "not set" end)
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:index, fn -> 42 end)

    ~H"<span data-index={@index}>a component: <%= @label %><%= if @theme do %> <%= @theme %><% end %></span>"
  end
end
