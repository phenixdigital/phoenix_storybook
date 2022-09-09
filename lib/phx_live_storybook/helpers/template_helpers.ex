defmodule PhxLiveStorybook.TemplateHelpers do
  @moduledoc false

  @story_regex ~r|<\.story[^\/]*\/>|
  @story_group_regex ~r|<\.story-group[^\/]*\/>|

  def set_template_id(template, story_id) do
    String.replace(template, ":story_id", to_string(story_id))
  end

  def story_template?(template) do
    not story_group_template?(template) and Regex.match?(@story_regex, template)
  end

  def story_group_template?(template) do
    Regex.match?(@story_group_regex, template)
  end

  def replace_template_story(template, story_markup) do
    String.replace(template, @story_regex, story_markup)
  end

  def replace_template_story_group(template, story_group_markup) do
    String.replace(template, @story_group_regex, story_group_markup)
  end
end
