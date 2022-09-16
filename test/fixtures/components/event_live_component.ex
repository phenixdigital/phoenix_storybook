defmodule EventLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <span>
      <button phx-click="greet_self" phx-target={@myself}>component: <%= @label %></button>
      <button phx-click="greet_parent">component: <%= @label %></button>
    </span>
    """
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end
end
