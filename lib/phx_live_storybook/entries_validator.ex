defmodule PhxLiveStorybook.EntriesValidator do
  @moduledoc false

  alias PhxLiveStorybook.{Attr, ComponentEntry, Story, StoryGroup}

  @doc """
  This validator ensures that:
  - component attributes ids are valid & unique
  - component attributes doc are valid
  - component attributes use proper types
  - component attributes default values match with their type
  - component attributes dont have both required and default
  - component stories ids are valid and unique
  - component stories attributes match with attribute's type
  - component stories contain all required attributes
  """
  def validate!(%ComponentEntry{path: path, attributes: attributes, stories: stories}) do
    validate_attribute_ids(path, attributes)
    validate_attribute_types(path, attributes)
    validate_attribute_doc(path, attributes)
    validate_default_types(path, attributes)
    validate_default_or_required(path, attributes)
    validate_story_ids(path, stories)
    validate_story_in_group_ids(path, stories)
    validate_story_attribute_types(path, attributes, stories)
    validate_required_attributes(path, attributes, stories)
    :ok
  end

  defp validate_attribute_ids(file_path, attributes) do
    Enum.reduce(attributes, MapSet.new(), fn %Attr{id: attr_id}, acc ->
      validate_type!(
        file_path,
        attr_id,
        :atom,
        "id for attribute #{inspect(attr_id)} must be an atom"
      )

      if MapSet.member?(acc, attr_id) do
        compile_error!(file_path, "duplicate attribute id: #{inspect(attr_id)}")
      else
        MapSet.put(acc, attr_id)
      end
    end)
  end

  @builtin_types [:string, :atom, :boolean, :integer, :float, :list, :block, :slot]
  defp validate_attribute_types(file_path, attributes) do
    for %Attr{id: attr_id, type: type} <- attributes do
      cond do
        type in [:any | @builtin_types] ->
          :ok

        is_atom(type) ->
          case Atom.to_string(type) do
            "Elixir." <> _ ->
              {:struct, type}

            _ ->
              bad_type!(attr_id, type, file_path)
          end

        true ->
          bad_type!(attr_id, type, file_path)
      end
    end
  end

  defp bad_type!(name, type, file) do
    compile_error!(file, """
    invalid type #{inspect(type)} for attr #{inspect(name)}. \
    The following types are supported:
      * any Elixir struct, such as URI, MyApp.User, etc
      * one of #{Enum.map_join(@builtin_types, ", ", &inspect/1)}
      * :any for all other types
    """)
  end

  defp validate_attribute_doc(file_path, attributes) do
    for %Attr{id: attr_id, doc: doc} <- attributes do
      validate_type!(
        file_path,
        doc,
        :string,
        "doc for attr #{inspect(attr_id)} is not a binary"
      )
    end
  end

  defp validate_default_types(file_path, attributes) do
    for %Attr{id: attr_id, type: type, default: default} <- attributes do
      validate_type!(
        file_path,
        default,
        type,
        "invalid type on default #{inspect(default)} for attr #{inspect(attr_id)} of type #{inspect(type)}"
      )
    end
  end

  defp validate_default_or_required(file_path, attributes) do
    for %Attr{id: attr_id, default: default, required: required} <- attributes do
      if required && !is_nil(default) do
        compile_error!(
          file_path,
          "only one of :required or :default must be given for attr #{inspect(attr_id)}"
        )
      end
    end
  end

  defp validate_story_ids(file_path, stories) do
    for %Story{id: story_id} <- stories, reduce: MapSet.new() do
      acc ->
        validate_type!(
          file_path,
          story_id,
          :atom,
          "id for story #{inspect(story_id)} must be an atom"
        )

        if MapSet.member?(acc, story_id) do
          compile_error!(file_path, "duplicate story id: #{inspect(story_id)}")
        else
          MapSet.put(acc, story_id)
        end
    end
  end

  defp validate_story_in_group_ids(file_path, stories) do
    for %StoryGroup{id: group_id, stories: stories} <- stories,
        %Story{id: story_id} <- stories,
        reduce: MapSet.new() do
      acc ->
        validate_type!(
          file_path,
          story_id,
          :atom,
          "id for story #{inspect(story_id)} in group #{inspect(group_id)} must be an atom"
        )

        if MapSet.member?(acc, {group_id, story_id}) do
          compile_error!(
            file_path,
            "duplicate story id: #{inspect(story_id)} in group #{inspect(group_id)}"
          )
        else
          MapSet.put(acc, {group_id, story_id})
        end
    end
  end

  defp validate_story_attribute_types(file_path, attributes, stories) do
    attr_types = for %Attr{id: attr_id, type: type} <- attributes, into: %{}, do: {attr_id, type}

    for %Story{id: story_id, attributes: attributes} <- stories,
        {attr_id, attr_value} <- attributes do
      case Map.get(attr_types, attr_id) do
        nil ->
          :ok

        type ->
          validate_type!(
            file_path,
            attr_value,
            type,
            "attribute #{inspect(attr_id)} in story #{inspect(story_id)} must be of type: #{inspect(type)}"
          )
      end
    end

    for %StoryGroup{id: group_id, stories: stories} <- stories,
        %Story{id: story_id, attributes: attributes} <- stories,
        {attr_id, attr_value} <- attributes do
      case Map.get(attr_types, attr_id) do
        nil ->
          :ok

        type ->
          validate_type!(
            file_path,
            attr_value,
            type,
            "attribute #{inspect(attr_id)} in story #{inspect(story_id)}, group #{inspect(group_id)} must be of type: #{inspect(type)}"
          )
      end
    end
  end

  defp validate_required_attributes(path, attributes, stories) do
    required_attributes =
      for %Attr{id: attr_id, required: true} <- attributes, into: MapSet.new(), do: attr_id

    for %Story{id: story_id, attributes: attributes} <- stories,
        attributes_keys = Map.keys(attributes) do
      for required_attribute <- required_attributes do
        if !Enum.member?(attributes_keys, required_attribute) do
          compile_error!(
            path,
            "required attribute #{inspect(required_attribute)} missing from story #{inspect(story_id)}"
          )
        end
      end
    end

    for %StoryGroup{id: group_id, stories: stories} <- stories,
        %Story{id: story_id, attributes: attributes} <- stories,
        attributes_keys = Map.keys(attributes) do
      for required_attribute <- required_attributes do
        if !Enum.member?(attributes_keys, required_attribute) do
          compile_error!(
            path,
            "required attribute #{inspect(required_attribute)} missing from story #{inspect(story_id)}, group #{inspect(group_id)}"
          )
        end
      end
    end
  end

  defp validate_type!(file, term, type, message) do
    unless match_attr_type?(term, type), do: compile_error!(file, message)
  end

  defp match_attr_type?(nil, _type), do: true
  defp match_attr_type?(_term, :any), do: true
  defp match_attr_type?(term, :string) when is_binary(term), do: true
  defp match_attr_type?(term, :atom) when is_atom(term), do: true
  defp match_attr_type?(term, :integer) when is_integer(term), do: true
  defp match_attr_type?(term, :float) when is_float(term), do: true
  defp match_attr_type?(term, :boolean) when is_boolean(term), do: true
  defp match_attr_type?(term, :list) when is_list(term), do: true
  defp match_attr_type?(term, :block) when is_binary(term), do: true
  defp match_attr_type?(term, :slot) when is_binary(term), do: true
  defp match_attr_type?(term, struct) when is_struct(term, struct), do: true
  defp match_attr_type?(_term, _type), do: false

  defp compile_error!(file, msg) do
    raise CompileError, file: file, description: msg
  end
end
