defmodule TreeStorybook.APage do
  use PhxLiveStorybook.Entry, :page

  def description, do: "a page"
  def icon, do: "fa fa-page"

  def render(assigns) do
    ~H"""
    <span>A Page</span>
    """
  end
end
