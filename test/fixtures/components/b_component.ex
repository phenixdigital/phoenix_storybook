defmodule BComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"<span>b component: <%= @label %></span>"
  end
end
