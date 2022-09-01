defmodule PhxLiveStorybook.ExtraAssignsHelpers do
  @moduledoc false

  alias PhxLiveStorybook.Attr

  @extra_assign_event_separator "/"
  @story_group_separator ":"

  def handle_set_story_assign(assign_params, extra_assigns, entry, mode \\ :nested) do
    {story_id, assign, value} =
      case String.split(assign_params, @extra_assign_event_separator) do
        [story_id, assign, value] ->
          {story_id, assign, value}

        _ ->
          raise "invalid set-story-assign syntax (should be set-story-assign/:story_id/:assign/:value)"
      end

    story_id = to_story_id(story_id)
    story_extra_assigns = to_story_extra_assigns(extra_assigns, story_id, mode)
    assign_id = String.to_atom(assign)

    story_extra_assigns =
      Map.put(
        story_extra_assigns,
        assign_id,
        to_value(value, assign_id, entry.attributes, "set-story-assign")
      )

    {story_id, story_extra_assigns}
  end

  def handle_toggle_story_assign(assign_params, extra_assigns, entry, mode \\ :nested) do
    context = "toggle-story-assign"

    {story_id, assign} =
      case String.split(assign_params, @extra_assign_event_separator) do
        [story_id, assign] ->
          {story_id, assign}

        _ ->
          raise "invalid #{context} syntax (should be #{context}/:story_id/:assign)"
      end

    story_id = to_story_id(story_id)
    story_extra_assigns = to_story_extra_assigns(extra_assigns, story_id, mode)
    current_value = Map.get(story_extra_assigns, String.to_atom(assign))
    check_type!(current_value, :boolean, context)

    assign_id = String.to_atom(assign)

    case declared_attr_type(assign_id, entry.attributes) do
      nil ->
        :ok

      :boolean ->
        :ok

      type ->
        raise(
          RuntimeError,
          "type mismatch in #{context}: attribute #{assign_id} is a #{type}, should be a boolean"
        )
    end

    story_extra_assigns = Map.put(story_extra_assigns, assign_id, !current_value)

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

  defp to_value("nil", _attr_id, _attributes, _context), do: nil

  defp to_value(val, attr_id, attributes, context) do
    case declared_attr_type(attr_id, attributes) do
      :atom -> val |> String.to_atom() |> check_type!(:atom, context)
      :boolean -> val |> String.to_atom() |> check_type!(:boolean, context)
      :integer -> val |> Integer.parse() |> check_type!(:integer, context)
      :float -> val |> Float.parse() |> check_type!(:float, context)
      _ -> val
    end
  end

  defp declared_attr_type(attr_id, attributes) do
    case Enum.find(attributes, fn %Attr{id: id} -> id == attr_id end) do
      %Attr{type: type} -> type
      _ -> nil
    end
  end

  defp check_type!(nil, _type, _context), do: nil
  defp check_type!(atom, :atom, _context) when is_atom(atom), do: atom
  defp check_type!(boolean, :boolean, _context) when is_boolean(boolean), do: boolean
  defp check_type!({integer, _}, :integer, _context) when is_integer(integer), do: integer
  defp check_type!({float, _}, :float, _context) when is_float(float), do: float

  defp check_type!(value, type, context) do
    raise(RuntimeError, "type mismatch in #{context}: #{value} is not a #{type}")
  end
end
