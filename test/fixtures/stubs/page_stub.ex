defmodule PhxLiveStorybook.PageStub do
  alias PhxLiveStorybook.Story.{PageBehaviour, StoryBehaviour}

  @behaviour StoryBehaviour
  @behaviour PageBehaviour

  @impl StoryBehaviour
  def storybook_type, do: :page

  @impl StoryBehaviour
  def description, do: "description"

  @impl PageBehaviour
  def navigation, do: []

  @impl PageBehaviour
  def render(_), do: false
end
