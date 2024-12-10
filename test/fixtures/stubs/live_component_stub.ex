defmodule PhoenixStorybook.LiveComponentStub do
  alias PhoenixStorybook.Story.{LiveComponentBehaviour, StoryBehaviour}

  @behaviour StoryBehaviour
  @behaviour LiveComponentBehaviour

  @impl StoryBehaviour
  def storybook_type, do: :live_component

  @impl StoryBehaviour
  def doc, do: nil

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
  def slots, do: []

  @impl LiveComponentBehaviour
  def variations, do: []

  @impl LiveComponentBehaviour
  def template, do: PhoenixStorybook.TemplateHelpers.default_template()

  @impl LiveComponentBehaviour
  def layout, do: :two_columns

  @impl LiveComponentBehaviour
  def render_only_function_source, do: false
end
