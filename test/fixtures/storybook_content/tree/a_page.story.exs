defmodule TreeStorybook.APage do
  use PhxLiveStorybook.Story, :page

  def description, do: "a page"

  def render(assigns) do
    ~H"""
    <span>A Page</span>
    """
  end
end
