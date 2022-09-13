defmodule PhxLiveStorybook.TemplateHelpers do
  @moduledoc false

  @story_regex ~r{(<\.lsb-story\/>)|(<\.lsb-story\s[^(\>)]*\/>)}
  @story_group_regex ~r{<\.lsb-story-group[^(\>)]*\/>}
  @html_attributes_regex ~r{(\w+)=((?:.(?!["']?\s+(?:\S+)=|\s*\/?[>]))+.["']?)?}

  def default_template, do: "<.lsb-story/>"

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

  def get_template(template, _story = %{template: :unset}), do: template
  def get_template(_tpl, _story = %{template: t}) when t in [nil, false], do: default_template()
  def get_template(template, nil), do: template
  def get_template(_tpl, _story = %{template: template}), do: template

  def extract_placeholder_attributes(template, inspect \\ nil) do
    cond do
      story_template?(template) ->
        extract_placeholder_attributes(template, @story_regex, inspect)

      story_group_template?(template) ->
        extract_placeholder_attributes(template, @story_group_regex, inspect)

      true ->
        ""
    end
  end

  defp extract_placeholder_attributes(template, regex, _inspect = nil) do
    [placeholder | _] = Regex.run(regex, template)

    @html_attributes_regex
    |> Regex.scan(placeholder)
    |> Enum.map_join(" ", fn [match, _, _] -> match end)
  end

  # When rendering a story from the component Playground, the playground will pass some context (
  # topic and story_id).
  # We use this context to wrap template values, unknown from the Playground, within a
  # `lsb_inspect/4` call that will broadcast values to the Playground.
  defp extract_placeholder_attributes(template, regex, {topic, story_id}) do
    [placeholder | _] = Regex.run(regex, template)

    @html_attributes_regex
    |> Regex.scan(placeholder)
    |> Enum.map_join(" ", fn [_, term1, term2] ->
      "#{term1}={lsb_inspect(#{inspect(topic)}, #{inspect(story_id)}, :#{term1}, #{inspect_val(term2)})}"
    end)
  end

  defp inspect_val(var) do
    if Regex.match?(~r/{.*}/, var) do
      String.replace(var, ["{", "}"], "")
    else
      var
    end
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
    indent = indent(indent_size)

    markup
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &(indent <> &1))
  end

  defp indent(0), do: ""
  defp indent(size), do: Enum.map_join(1..size, fn _ -> " " end)
end
