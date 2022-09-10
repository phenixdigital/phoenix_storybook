defmodule PhxLiveStorybook.TemplateHelpers do
  @moduledoc false

  @story_regex ~r|<\.story([\s]*[\w]*)*\/>|
  @story_group_regex ~r|<\.story-group([\s]*[\w]*)*\/>|

  def set_template_id(template, story_id) do
    String.replace(template, ":story_id", to_string(story_id))
  end

  def story_template?(template) do
    Regex.match?(@story_regex, template)
  end

  def story_group_template?(template) do
    Regex.match?(@story_group_regex, template)
  end

  def code_hidden?(template) do
    String.contains?(template, "lsb-code-hidden")
  end

  def replace_template_story(template, story_markup, indent? \\ false) do
    replace_in_template(template, @story_regex, story_markup, indent?)
  end

  def replace_template_story_group(template, story_group_markup, indent? \\ false) do
    replace_in_template(template, @story_group_regex, story_group_markup, indent?)
  end

  defp replace_in_template(template, regex, markup, _indent? = true) do
    template
    |> String.split("\n")
    |> Enum.map_join("\n", fn line ->
      if Regex.match?(regex, line) do
        indent_size = indent_size(line)
        indent(markup, indent_size)
      else
        line
      end
    end)
  end

  defp replace_in_template(template, regex, markup, _indent? = false) do
    String.replace(template, regex, markup)
  end

  defp indent_size(line) do
    if String.starts_with?(line, " ") do
      [indent | _] = line |> String.codepoints() |> Enum.chunk_by(&(&1 == " "))
      length(indent)
    else
      0
    end
  end

  defp indent(markup, indent_size) do
    indent = Enum.map_join(1..indent_size, fn _ -> " " end)

    markup
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &(indent <> &1))
  end
end
