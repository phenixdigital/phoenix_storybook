defmodule TreeStorybook.APage do
  use PhxLiveStorybook.Story, :page

  def doc, do: "a page"

  def render(assigns) do
    ~H"""
    <span>A Page</span>
    """
  end
end
