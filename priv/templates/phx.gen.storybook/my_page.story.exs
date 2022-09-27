defmodule Storybook.MyPage do
  # See https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.Story.html for full story
  # documentation.
  use PhxLiveStorybook.Story, :page

  def description, do: "My page description"

  # Declare an optional tab-based navigation in your page:
  def navigation do
    [
      {:tab_one, "Tab One", "fa fa-dice-one"},
      {:tab_two, "Tab Two", "fa fa-dice-two"}
    ]
  end

  # This is a dummy fonction that you should replace with your own HEEx content.
  def render(assigns) do
    ~H"<h1>An example page</h1>"
  end
end
