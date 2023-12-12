defmodule EventComponent do
  use Phoenix.Component

  def component(assigns) do
    assigns =
      assigns
      |> assign_new(:theme, fn -> nil end)
      |> assign_new(:label, fn -> "" end)

    ~H"""
    <button id="event-component" phx-click="greet">component: <%= @label %><%= if @theme do %> <%= @theme %><% end %></button>
    """
  end
end
