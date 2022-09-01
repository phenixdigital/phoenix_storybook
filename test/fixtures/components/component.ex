defmodule Component do
  use Phoenix.Component

  def component(assigns) do
    assigns =
      assigns
      |> assign_new(:theme, fn -> "not set" end)
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:index, fn -> 42 end)

    ~H"<span data-index={@index}>component: <%= @label %><%= if @theme do %> <%= @theme %><% end %></span>"
  end
end
