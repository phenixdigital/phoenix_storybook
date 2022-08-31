defmodule PhxLiveStorybook.ExtraAssignsHelpers do
  @moduledoc false

  @extra_assign_event_separator "/"
  @story_group_separator ":"

  def handle_set_story_assign(assign_params, extra_assigns, mode \\ :nested) do
    {story_id, assign, value} =
      case String.split(assign_params, @extra_assign_event_separator) do
        [story_id, assign, value] ->
          {story_id, assign, value}

        _ ->
          raise "invalid set-story-assign syntax (should be set-story-assign/:story_id/:assign/:value)"
      end

    story_id = to_story_id(story_id)
    story_extra_assigns = to_story_extra_assigns(extra_assigns, story_id, mode)
    story_extra_assigns = Map.put(story_extra_assigns, String.to_atom(assign), to_value(value))

    {story_id, story_extra_assigns}
  end

  def handle_toggle_story_assign(assign_params, extra_assigns, mode \\ :nested) do
    {story_id, assign} =
      case String.split(assign_params, @extra_assign_event_separator) do
        [story_id, assign] ->
          {story_id, assign}

        _ ->
          raise "invalid toggle-story-assign syntax (should be toggle-story-assign/:story_id/:assign)"
      end

    story_id = to_story_id(story_id)
    story_extra_assigns = to_story_extra_assigns(extra_assigns, story_id, mode)
    current_value = Map.get(story_extra_assigns, String.to_atom(assign))
    story_extra_assigns = Map.put(story_extra_assigns, String.to_atom(assign), !current_value)

    {story_id, story_extra_assigns}
  end

  defp to_story_id(story_id) do
    if String.contains?(story_id, @story_group_separator) do
      [group_id, story_id] = String.split(story_id, @story_group_separator)
      {String.to_atom(group_id), String.to_atom(story_id)}
    else
      String.to_atom(story_id)
    end
  end

  defp to_story_extra_assigns(extra_assigns, story_id, :nested) do
    Map.get(extra_assigns, story_id)
  end

  defp to_story_extra_assigns(extra_assigns, _story_id, :flat) do
    extra_assigns
  end

  defp to_value("true"), do: true
  defp to_value("false"), do: false
  defp to_value(val), do: val
end
