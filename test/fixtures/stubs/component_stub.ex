defmodule PhxLiveStorybook.ComponentStub do
  alias PhxLiveStorybook.Story.{ComponentBehaviour, StoryBehaviour}

  @behaviour StoryBehaviour
  @behaviour ComponentBehaviour

  @impl StoryBehaviour
  def storybook_type, do: :component

  @impl StoryBehaviour
  def name, do: "component"

  @impl StoryBehaviour
  def description, do: "description"

  @impl StoryBehaviour
  def icon, do: nil

  @impl ComponentBehaviour
  def function, do: fn -> "" end

  @impl ComponentBehaviour
  def container, do: :div

  @impl ComponentBehaviour
  def imports, do: []

  @impl ComponentBehaviour
  def aliases, do: []

  @impl ComponentBehaviour
  def attributes, do: []

  @impl ComponentBehaviour
  def variations, do: []

  @impl ComponentBehaviour
  def template, do: PhxLiveStorybook.TemplateHelpers.default_template()
end
