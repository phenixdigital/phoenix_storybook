defmodule Component do
  use Phoenix.Component

  @doc """
  Component first doc paragraph.
  Still first paragraph.

  Second paragraph.
  """

  attr :theme, :atom, default: nil
  attr :label, :string, default: "", doc: "Set your component label"

  attr :index, :integer,
    default: 42,
    doc: """
    This is a multi-line

    attr documentation.
    """

  def component(assigns) do
    ~H"""
    <span data-index={@index}>
      component: <%= @label %>
      <%= if @theme do %>
        <%= @theme %>
      <% end %>
    </span>
    """
  end

  @doc """
  Should not be extracted in Component.component/1 source code.
  """
  def unrelated_function, do: nil
end
