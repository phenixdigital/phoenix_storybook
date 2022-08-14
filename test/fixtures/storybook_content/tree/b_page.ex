defmodule TreeStorybook.BPage do
  use PhxLiveStorybook.Entry, :page

  def description, do: "b page"

  def navigation do
    [{:tab_1, "Tab 1", ""}, {:tab_2, "Tab 2", ""}]
  end

  def render(assigns) do
    ~H"""
    <span>B Page: <%= @tab %></span>
    """
  end
end
