defmodule TreeStorybook.APage do
  use PhoenixStorybook.Story, :page

  def doc, do: """"
  a page

  multiline doc
  """

  def render(assigns) do
    ~H"""
    <span>A Page</span>
    """
  end
end
