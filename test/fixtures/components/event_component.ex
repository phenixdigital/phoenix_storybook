defmodule EventComponent do
  use Phoenix.Component

  @doc """
  Component doc

  ```
  Some code
  ```

  ```css
  .my-class {
    margin: 0;
  }
  ```
  """
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
