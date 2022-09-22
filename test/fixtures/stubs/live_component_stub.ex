defmodule PhxLiveStorybook.LiveComponentStub do
  alias PhxLiveStorybook.Story.{LiveComponentBehaviour, StoryBehaviour}

  @behaviour StoryBehaviour
  @behaviour LiveComponentBehaviour

  @impl StoryBehaviour
  def storybook_type, do: :live_component

  @impl StoryBehaviour
  def description, do: "description"

  @impl LiveComponentBehaviour
  def component, do: nil

  @impl LiveComponentBehaviour
  def container, do: :div

  @impl LiveComponentBehaviour
  def imports, do: []

  @impl LiveComponentBehaviour
  def aliases, do: []

  @impl LiveComponentBehaviour
  def attributes, do: []

  @impl LiveComponentBehaviour
  def variations, do: []

  @impl LiveComponentBehaviour
  def template, do: PhxLiveStorybook.TemplateHelpers.default_template()
end
