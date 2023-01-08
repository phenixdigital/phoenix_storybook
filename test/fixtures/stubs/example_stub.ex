defmodule PhxLiveStorybook.ExampleStub do
  alias PhxLiveStorybook.Story.{ExampleBehaviour, StoryBehaviour}

  @behaviour StoryBehaviour
  @behaviour ExampleBehaviour

  @impl StoryBehaviour
  def storybook_type, do: :example

  @impl StoryBehaviour
  def doc, do: "description"

  @impl ExampleBehaviour
  def extra_sources, do: []
end
