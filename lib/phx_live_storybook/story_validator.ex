defmodule PhxLiveStorybook.StoryValidator do
  @moduledoc false

  alias PhxLiveStorybook.{Attr, Variation, VariationGroup}

  @doc """
  This validator ensures that all stories have their properties filled with proper
  datatypes and that attribute declarations are consistent accross variations.
  """
  def validate!(story) do
    case story.storybook_type() do
      :component -> validate_component!(story)
      :live_component -> validate_component!(story)
      :page -> story
    end
  end

  defp validate_component!(story) do
    file_path = story.__info__(:compile)[:source]
    {attributes, variations} = {story.attributes(), story.variations()}
    validate_story_description!(file_path, story)
    validate_story_component!(file_path, story)
    validate_story_function!(file_path, story)
    validate_story_aliases!(file_path, story)
    validate_story_imports!(file_path, story)
    validate_story_container!(file_path, story)
    validate_story_template!(file_path, story)
    validate_attribute_list_type!(file_path, story)
    validate_attribute_ids!(file_path, attributes)
    validate_attribute_types!(file_path, attributes)
    validate_attribute_doc!(file_path, attributes)
    validate_attribute_default_types!(file_path, attributes)
    validate_attribute_required_type!(file_path, attributes)
    validate_attribute_default_or_required!(file_path, attributes)
    validate_attribute_values(file_path, attributes)
    validate_attribute_block_unicity!(file_path, attributes)
    validate_variation_list_type!(file_path, variations)
    validate_variation_in_group_list_type!(file_path, variations)
    validate_variation_ids!(file_path, variations)
    validate_variation_in_group_ids!(file_path, variations)
    validate_variation_description!(file_path, variations)
    validate_variation_in_group_description!(file_path, variations)
    validate_variation_let!(file_path, variations)
    validate_variation_in_group_let!(file_path, variations)
    validate_variation_attributes_map_type!(file_path, variations)
    validate_variation_in_group_attributes_map_type!(file_path, variations)
    validate_variation_attribute_types!(file_path, attributes, variations)
    validate_variation_attribute_values(file_path, attributes, variations)
    validate_variation_required_attributes!(file_path, attributes, variations)
    validate_variation_required_block!(file_path, attributes, variations)
    validate_variation_required_slots!(file_path, attributes, variations)
    validate_variation_template!(file_path, variations)
    validate_variation_in_group_template!(file_path, variations)
    story
  end

  defp validate_story_description!(file_path, story) do
    validate_type!(
      file_path,
      story.description(),
      :string,
      "story description must be a binary"
    )
  end

  defp validate_story_component!(file_path, story) do
    if story.storybook_type() == :live_component do
      validate_type!(file_path, story.component(), :atom, "story component must be a module")
    end
  end

  defp validate_story_function!(file_path, story) do
    if story.storybook_type() == :component do
      validate_type!(file_path, story.function(), :function, "story function must be a function")
    end
  end

  defp validate_story_aliases!(file_path, story) do
    msg = "story aliases must be a list of atoms"
    validate_type!(file_path, story.aliases, :list, msg)

    for alias_item <- story.aliases || [],
        do: validate_type!(file_path, alias_item, :atom, msg)
  end

  defp validate_story_imports!(file_path, story) do
    msg = "story imports must be a list of {atom, [{atom, integer}]}"
    validate_type!(file_path, story.aliases, :list, msg)

    for import_item <- story.imports || [] do
      validate_type!(file_path, import_item, {:tuple, 2}, msg)
      {mod, functions} = import_item
      validate_type!(file_path, mod, :atom, msg)
      validate_type!(file_path, functions, :list, msg)

      for function <- functions do
        validate_type!(file_path, function, {:tuple, 2}, msg)
        {fun, arity} = function
        validate_type!(file_path, fun, :atom, msg)
        validate_type!(file_path, arity, :integer, msg)
      end
    end
  end

  defp validate_story_container!(file_path, story) do
    unless story.container in ~w(nil div iframe)a do
      compile_error!(file_path, "story container must be either :div or :iframe")
    end
  end

  defp validate_story_template!(file_path, story) do
    validate_type!(file_path, story.template, :string, "story template must be a binary")
  end

  defp validate_attribute_list_type!(file_path, story) do
    msg = "story attributes must be a list of %Attr{}"
    validate_type!(file_path, story.attributes, :list, msg)
    for attr <- story.attributes, do: validate_type!(file_path, attr, Attr, msg)
  end

  defp validate_attribute_ids!(file_path, attributes) do
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

  @builtin_types [:string, :atom, :boolean, :integer, :float, :list, :map, :block, :slot]
  defp validate_attribute_types!(file_path, attributes) do
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

  defp validate_attribute_doc!(file_path, attributes) do
    for %Attr{id: attr_id, doc: doc} <- attributes do
      validate_type!(
        file_path,
        doc,
        :string,
        "doc for attr #{inspect(attr_id)} is not a binary"
      )
    end
  end

  defp validate_attribute_default_types!(file_path, attributes) do
    for %Attr{id: attr_id, type: type, default: default} <- attributes do
      validate_type!(
        file_path,
        default,
        type,
        "invalid type on default #{inspect(default)} for attr #{inspect(attr_id)} of type #{inspect(type)}"
      )
    end
  end

  defp validate_attribute_required_type!(file_path, attributes) do
    for %Attr{id: attr_id, required: required} <- attributes do
      validate_type!(
        file_path,
        required,
        :boolean,
        "required for attr #{inspect(attr_id)} must be of type :boolean"
      )
    end
  end

  defp validate_attribute_default_or_required!(file_path, attributes) do
    for %Attr{id: attr_id, default: default, required: required} <- attributes do
      if required && !is_nil(default) do
        compile_error!(
          file_path,
          "only one of :required or :default must be given for attr #{inspect(attr_id)}"
        )
      end
    end
  end

  defp validate_attribute_values(file_path, attributes) do
    for %Attr{id: attr_id, values: values, examples: examples} <- attributes,
        !is_nil(values),
        !is_nil(examples) do
      compile_error!(
        file_path,
        "examples and values for attr #{inspect(attr_id)} cannot be set at the same time"
      )
    end

    for %Attr{id: attr_id, type: type, values: values} <- attributes, !is_nil(values) do
      msg = "values for attr #{inspect(attr_id)} must be a list of #{inspect(type)}"
      validate_type!(file_path, values, [:list, :range], msg)
      for val <- values, do: validate_type!(file_path, val, type, msg)
    end

    for %Attr{id: attr_id, type: type, examples: examples} <- attributes, !is_nil(examples) do
      msg = "examples for attr #{inspect(attr_id)} must be a list of #{inspect(type)}"
      validate_type!(file_path, examples, [:list, :range], msg)
      for val <- examples, do: validate_type!(file_path, val, type, msg)
    end
  end

  defp validate_attribute_block_unicity!(file_path, attributes) do
    if Enum.count(attributes, &(&1.type == :block)) > 1 do
      compile_error!(file_path, "at most a single block attribute can be declared")
    end
  end

  defp validate_variation_list_type!(file_path, variations) do
    msg = "story variations must be a list of %Variation{} or %VariationGroup{}"
    validate_type!(file_path, variations, :list, msg)

    for variation <- variations,
        do: validate_type!(file_path, variation, [Variation, VariationGroup], msg)
  end

  defp validate_variation_in_group_list_type!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations} <- variations do
      msg = "variations in group #{inspect(group_id)} must be a list of %Variation{}"
      validate_type!(file_path, variations, :list, msg)
      for variation <- variations, do: validate_type!(file_path, variation, Variation, msg)
    end
  end

  defp validate_variation_ids!(file_path, variations) do
    for %Variation{id: variation_id} <- variations, reduce: MapSet.new() do
      acc ->
        validate_type!(
          file_path,
          variation_id,
          :atom,
          "id for variation #{inspect(variation_id)} must be an atom"
        )

        if MapSet.member?(acc, variation_id) do
          compile_error!(file_path, "duplicate variation id: #{inspect(variation_id)}")
        else
          MapSet.put(acc, variation_id)
        end
    end
  end

  defp validate_variation_in_group_ids!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id} <- variations,
        reduce: MapSet.new() do
      acc ->
        validate_type!(
          file_path,
          variation_id,
          :atom,
          "id for variation #{inspect(variation_id)} in group #{inspect(group_id)} must be an atom"
        )

        if MapSet.member?(acc, {group_id, variation_id}) do
          compile_error!(
            file_path,
            "duplicate variation id: #{inspect(variation_id)} in group #{inspect(group_id)}"
          )
        else
          MapSet.put(acc, {group_id, variation_id})
        end
    end
  end

  defp validate_variation_description!(file_path, variations) do
    for %Variation{id: variation_id, description: description} <- variations do
      msg = "description in variation #{inspect(variation_id)} must be a binary"
      validate_type!(file_path, description, :string, msg)
    end
  end

  defp validate_variation_in_group_description!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, description: description} <- variations do
      msg =
        "description in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be a binary"

      validate_type!(file_path, description, :string, msg)
    end
  end

  defp validate_variation_let!(file_path, variations) do
    for %Variation{id: variation_id, let: let} <- variations do
      msg = "let in variation #{inspect(variation_id)} must be an atom"
      validate_type!(file_path, let, :atom, msg)
    end
  end

  defp validate_variation_in_group_let!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, let: let} <- variations do
      msg =
        "let in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be an atom"

      validate_type!(file_path, let, :atom, msg)
    end
  end

  defp validate_variation_attributes_map_type!(file_path, variations) do
    for %Variation{id: variation_id, attributes: attributes} <- variations do
      msg = "attributes in variation #{inspect(variation_id)} must be a map"
      validate_type!(file_path, attributes, :map, msg)
    end
  end

  defp validate_variation_in_group_attributes_map_type!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, attributes: attributes} <- variations do
      msg =
        "attributes in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be a map"

      validate_type!(file_path, attributes, :map, msg)
    end
  end

  defp validate_variation_attribute_types!(file_path, attributes, variations) do
    attr_types = for %Attr{id: attr_id, type: type} <- attributes, into: %{}, do: {attr_id, type}

    for %Variation{id: variation_id, attributes: attributes, block: block, slots: slots} <-
          variations do
      for {attr_id, attr_value} <- attributes do
        case Map.get(attr_types, attr_id) do
          nil ->
            :ok

          type ->
            validate_type!(
              file_path,
              attr_value,
              type,
              "attribute #{inspect(attr_id)} in variation #{inspect(variation_id)} must be of type: #{inspect(type)}"
            )
        end
      end

      msg = "slots in variation #{inspect(variation_id)} must be a list of binary"
      validate_type!(file_path, slots, :list, msg)
      for slot <- slots, do: validate_type!(file_path, slot, :string, msg)

      validate_type!(
        file_path,
        block,
        :block,
        "block in variation #{inspect(variation_id)} must be a binary"
      )
    end

    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, attributes: attributes, block: block, slots: slots} <-
          variations do
      for {attr_id, attr_value} <- attributes do
        case Map.get(attr_types, attr_id) do
          nil ->
            :ok

          type ->
            validate_type!(
              file_path,
              attr_value,
              type,
              "attribute #{inspect(attr_id)} in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be of type: #{inspect(type)}"
            )
        end
      end

      msg =
        "slots in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be a list of binary"

      validate_type!(file_path, slots, :list, msg)
      for slot <- slots, do: validate_type!(file_path, slot, :string, msg)

      validate_type!(
        file_path,
        block,
        :block,
        "block in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be a binary"
      )
    end
  end

  defp validate_variation_attribute_values(file_path, attributes, variations) do
    attr_values =
      for %Attr{id: attr_id, values: values} <- attributes,
          !is_nil(values),
          into: %{},
          do: {attr_id, values}

    for %Variation{id: variation_id, attributes: attributes} <- variations do
      for {attr_id, attr_value} <- attributes do
        case Map.get(attr_values, attr_id) do
          nil ->
            :ok

          values ->
            unless attr_value in values do
              compile_error!(
                file_path,
                "attribute #{inspect(attr_id)} in variation #{inspect(variation_id)} must be one of #{inspect(values)}"
              )
            end
        end
      end
    end

    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, attributes: attributes} <- variations do
      for {attr_id, attr_value} <- attributes do
        case Map.get(attr_values, attr_id) do
          nil ->
            :ok

          values ->
            unless attr_value in values do
              compile_error!(
                file_path,
                "attribute #{inspect(attr_id)} in variation #{inspect(variation_id)}, group #{inspect(group_id)} must be one of #{inspect(values)}"
              )
            end
        end
      end
    end
  end

  defp validate_variation_required_attributes!(file_path, attributes, variations) do
    required_attributes =
      for %Attr{id: attr_id, type: type, required: true} <- attributes,
          type not in [:slot, :block],
          into: MapSet.new(),
          do: attr_id

    for %Variation{id: variation_id, attributes: attributes} <- variations,
        attributes_keys = Map.keys(attributes) do
      for required_attribute <- required_attributes do
        unless Enum.member?(attributes_keys, required_attribute) do
          compile_error!(
            file_path,
            "required attribute #{inspect(required_attribute)} missing from variation #{inspect(variation_id)}"
          )
        end
      end
    end

    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, attributes: attributes} <- variations,
        attributes_keys = Map.keys(attributes) do
      for required_attribute <- required_attributes do
        unless Enum.member?(attributes_keys, required_attribute) do
          compile_error!(
            file_path,
            "required attribute #{inspect(required_attribute)} missing from variation #{inspect(variation_id)}, group #{inspect(group_id)}"
          )
        end
      end
    end
  end

  defp validate_variation_required_block!(file_path, attributes, variations) do
    has_required_block? = Enum.any?(attributes, &(&1.type == :block && &1.required))

    if has_required_block? do
      for variation = %Variation{id: variation_id} <- variations do
        unless variation.block do
          compile_error!(
            file_path,
            "required block missing from variation #{inspect(variation_id)}"
          )
        end
      end

      for %VariationGroup{id: group_id, variations: variations} <- variations,
          variation = %Variation{id: variation_id} <- variations do
        unless variation.block do
          compile_error!(
            file_path,
            "required block missing from variation #{inspect(variation_id)}, group #{inspect(group_id)}"
          )
        end
      end
    end
  end

  defp validate_variation_required_slots!(file_path, attributes, variations) do
    required_slots =
      for %Attr{id: attr_id, type: :slot, required: true} <- attributes,
          into: MapSet.new(),
          do: attr_id

    for %Variation{id: variation_id, slots: slots} <- variations do
      for required_slot <- required_slots do
        unless Enum.any?(slots, &matching_slot?(required_slot, &1)) do
          compile_error!(
            file_path,
            "required slot #{inspect(required_slot)} missing from variation #{inspect(variation_id)}"
          )
        end
      end
    end

    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, slots: slots} <- variations do
      for required_slot <- required_slots do
        unless Enum.any?(slots, &matching_slot?(required_slot, &1)) do
          compile_error!(
            file_path,
            "required slot #{inspect(required_slot)} missing from variation #{inspect(variation_id)}, group #{inspect(group_id)}"
          )
        end
      end
    end
  end

  defp validate_variation_template!(file_path, variations) do
    for %Variation{id: var_id, template: template} when template not in [:unset, nil, false] <-
          variations do
      validate_type!(
        file_path,
        template,
        :string,
        "template in variation #{inspect(var_id)} must be a binary or a falsy value"
      )
    end
  end

  defp validate_variation_in_group_template!(file_path, variations) do
    for %VariationGroup{id: group_id, variations: variations, template: template} <- variations do
      if template != :unset do
        validate_type!(
          file_path,
          template,
          :string,
          "template in variation_group #{inspect(group_id)} must be a binary"
        )
      end

      for %Variation{id: variation_id, template: template}
          when template not in [nil, false, :unset] <-
            variations do
        compile_error!(
          file_path,
          "template in a group variation cannot be set (variation #{inspect(variation_id)}, group #{inspect(group_id)})"
        )
      end
    end
  end

  defp validate_type!(file, term, types, message) when is_list(types) do
    unless Enum.any?(types, &match_attr_type?(term, &1)), do: compile_error!(file, message)
  end

  defp validate_type!(file, term, type, message) do
    unless match_attr_type?(term, type), do: compile_error!(file, message)
  end

  defp match_attr_type?(nil, _type), do: true
  defp match_attr_type?(_term, :any), do: true
  defp match_attr_type?(term, {:tuple, s}) when is_tuple(term) and tuple_size(term) == s, do: true
  defp match_attr_type?(term, :string) when is_binary(term), do: true
  defp match_attr_type?(term, :atom) when is_atom(term), do: true
  defp match_attr_type?(term, :integer) when is_integer(term), do: true
  defp match_attr_type?(term, :float) when is_float(term), do: true
  defp match_attr_type?(term, :boolean) when is_boolean(term), do: true
  defp match_attr_type?(term, :list) when is_list(term), do: true
  defp match_attr_type?(_min.._max, :range), do: true
  defp match_attr_type?(term, :map) when is_map(term), do: true
  defp match_attr_type?(term, :block) when is_binary(term), do: true
  defp match_attr_type?(term, :slot) when is_binary(term), do: true
  defp match_attr_type?(term, :function) when is_function(term), do: true
  defp match_attr_type?(term, struct) when is_struct(term, struct), do: true
  defp match_attr_type?(_term, _type), do: false

  defp compile_error!(file_path, msg) do
    raise CompileError, file: file_path, description: msg
  end

  defp matching_slot?(slot_id, slot) do
    Regex.match?(~r|<:#{slot_id}.*</:#{slot_id}>|s, slot)
  end
end
