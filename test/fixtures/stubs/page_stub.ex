defmodule PhxLiveStorybook.PageStub do
  import Phoenix.Component
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
  def render(assigns), do: ~H""
end
