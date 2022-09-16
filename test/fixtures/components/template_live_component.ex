defmodule TemplateLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:status, fn -> false end)

    ~H"""
    <span>template_live_component: <%= @label %> / status: <%= @status %></span>
    """
  end
end
