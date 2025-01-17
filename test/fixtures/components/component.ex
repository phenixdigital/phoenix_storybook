defmodule Component do
  use Phoenix.Component

  @doc """
  Component first doc paragraph.
  Still first paragraph.

  Second paragraph.

  ## Examples

      <.component label="hello" />

  and

      iex> Component.component(%{label: "hello"})
      %Phoenix.LiveView.Rendered{}

  and

  ```heex
  <.component theme={:cool} />
  ```

  and

  ```elixir
  iex> Component.component(%{theme: :boring})
  %Phoenix.LiveView.Rendered{}
  ```
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

  # In tests, we use
  # "should not appear" keyphrase in comments and docs to
  # check that the source code is not extracted

  # attrs, comments, and docs that should not appear in the source code
  attr :index2, :integer, default: 42
  attr :label2, :string, default: "", doc: "Set your component label"

  @doc """
  This should not appear in Component.component/1 source code.
  """
  def another_component(assigns) do
    ~H"""
    <span data-index={@index2}>
      another_component: <%= @label2 %>
    </span>
    """
  end

  @doc """
  Should not be extracted in Component.component/1 source code.
  """
  def unrelated_function, do: nil
end
