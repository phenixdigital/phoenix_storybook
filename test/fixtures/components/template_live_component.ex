defmodule TemplateLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:status, fn -> false end)
      |> assign_rest()

    ~H"""
    <span {@rest}>template_live_component: <%= @label %> / status: <%= @status %></span>
    """
  end

  defp assign_rest(assigns) do
    rest = assigns_to_attributes(assigns, [:label, :status])
    assign(assigns, rest: rest)
  end
end
