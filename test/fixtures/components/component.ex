defmodule Component do
  use Phoenix.Component

  def component(assigns) do
    assigns =
      assigns
      |> assign_new(:theme, fn -> "not set" end)
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:index, fn -> 42 end)
      |> assign_rest()

    ~H"<span data-index={@index} {@rest}>component: <%= @label %><%= if @theme do %> <%= @theme %><% end %></span>"
  end

  defp assign_rest(assigns) do
    rest = assigns_to_attributes(assigns, [:theme, :label, :index])
    assign(assigns, rest: rest)
  end
end
