defmodule PhoenixStorybook.CoreComponents do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.HTML.Form, only: [normalize_value: 2, options_for_select: 2]

  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField
  attr :options, :list
  attr :multiple, :boolean, default: false

  attr :rest, :global,
    include: ~w(autocomplete disabled max min multiple placeholder readonly required step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select id={@id} name={@name} multiple={@multiple} {@rest}>
      {options_for_select(@options, @value)}
    </select>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(assigns) do
    ~H"""
    <input type={@type} id={@id} name={@name} value={normalize_value(@type, @value)} {@rest} />
    """
  end
end
