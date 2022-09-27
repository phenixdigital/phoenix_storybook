defmodule Storybook.MyPage do
  use PhxLiveStorybook.Story, :page
  import Phoenix.LiveView.Helpers # remove this line once you import your component

  def description, do: "My page description"

  # This is a dummy fonction that you should replace with your own heex content.
  def render(assigns) do
    ~H"<h1>An example page</h1>"
  end
end
