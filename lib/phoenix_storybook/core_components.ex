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

  def input(assigns = %{field: field = %Phoenix.HTML.FormField{}}) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns = %{type: "select"}) do
    ~H"""
    <select id={@id} name={@name} multiple={@multiple} {@rest}>
      {options_for_select(@options, @value)}
    </select>
    """
  end

  def input(assigns = %{type: "hidden"}) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(assigns) do
    ~H"""
    <input type={@type} id={@id} name={@name} value={normalize_value(@type, @value)} {@rest} />
    """
  end

  @doc """
  Renders a keyboard key using a `<kbd>` element with minimal styling.

  ## Examples

      <.kbd text="⌘" />
      <.kbd text="Ctrl" /> + <.kbd text="K" />
      <.kbd text="Enter" class="psb:h-8" />
  """
  attr :text, :string, required: true, doc: "The key label to render."
  attr :class, :any, default: nil, doc: "Additional CSS classes"
  attr :rest, :global, doc: "Any HTML attribute"

  def kbd(assigns) do
    ~H"""
    <kbd
      class={[
        "psb:inline psb:px-1.5 psb:pt-1 psb:rounded-sm",
        "psb:border psb:border-border psb:bg-muted psb:shadow-xs",
        "psb:font-mono psb:text-xs psb:font-medium psb:text-muted-foreground",
        @class
      ]}
      {@rest}
    >
      {@text}
    </kbd>
    """
  end
end
