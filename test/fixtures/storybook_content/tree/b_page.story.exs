defmodule TreeStorybook.BPage do
  use PhxLiveStorybook.Story, :page

  def description, do: "b page"

  def navigation do
    [{:tab_1, "Tab 1", nil}, {:tab_2, "Tab 2", nil}]
  end

  def render(assigns) do
    ~H"""
    <span>B Page: <%= @tab %></span>
    """
  end
end
