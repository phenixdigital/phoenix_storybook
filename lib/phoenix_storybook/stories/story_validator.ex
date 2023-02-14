defmodule PhoenixStorybook.Stories.StoryValidator do
  @moduledoc false

  alias PhoenixStorybook.Stories.{Attr, Slot, Variation, VariationGroup}
  import PhoenixStorybook.ValidationHelpers
  require Logger

  @dialyzer {:no_return, bad_type!: 3}

  @doc """
  This validator ensures that all stories have their properties filled with proper datatypes
  and that attribute declarations are consistent accross variations.
  Returns either `{:ok, story}` or `{:error, message}`.
  """
  def validate(story) do
    story = validate!(story)
    {:ok, story}
  rescue
    e ->
      message = "Could not validate #{inspect(story)}"
      exception = Exception.format(:error, e, __STACKTRACE__)
      Logger.error(message <> "\n\n" <> exception)
      {:error, message, exception}
  end

  @doc """
  Same as `validate/1`, but raises a `CompileError` if the story is invalid.
  """
  def validate!(story) do
    case story.storybook_type() do
      :component -> validate_component!(story)
      :live_component -> validate_component!(story)
      :page -> validate_page!(story)
      :example -> validate_example!(story)
    end
  end

  defp validate_page!(story) do
    file_path = story.__info__(:compile)[:source]
    validate_page_doc!(file_path, story)
    validate_page_navigation!(file_path, story)
    story
  end

  defp validate_example!(story) do
    file_path = story.__info__(:compile)[:source]
    validate_page_doc!(file_path, story)
    validate_example_extra_sources!(file_path, story)
    story
  end

  defp validate_component!(story) do
    file_path = story.__info__(:compile)[:source]
    {attributes, slots, variations} = {story.attributes(), story.slots(), story.variations()}
    validate_story_component!(file_path, story)
    validate_component_function!(file_path, story)
    validate_component_aliases!(file_path, story)
    validate_component_imports!(file_path, story)
    validate_component_container!(file_path, story)
    validate_component_template!(file_path, story)
    validate_attribute_list_type!(file_path, attributes)
    validate_attribute_ids!(file_path, attributes)
    validate_attribute_types!(file_path, attributes)
    validate_attribute_doc!(file_path, attributes)
    validate_attribute_default_types!(file_path, attributes)
    validate_attribute_required!(file_path, attributes)
    validate_attribute_default_or_required!(file_path, attributes)
    validate_attribute_values!(file_path, attributes)
    validate_attribute_global_options!(file_path, attributes)
    validate_slot_list_type!(file_path, slots)
    validate_slot_ids!(file_path, slots)
    validate_slot_doc!(file_path, slots)
    validate_slot_required!(file_path, slots)
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
    validate_variation_required_slots!(file_path, slots, variations)
    validate_variation_template!(file_path, variations)
    validate_variation_in_group_template!(file_path, variations)
    story
  end

  defp validate_page_doc!(file_path, story) do
    msg = "page doc must be a binary or a list of binary"

    unless match_attr_type?(story.doc(), :string) do
      validate_type!(file_path, story.doc(), :list, msg)

      for paragraph <- story.doc() do
        validate_type!(file_path, paragraph, :string, msg)
      end
    end
  end

  defp validate_page_navigation!(file_path, story) do
    msg = "page navigation must be a list of {atom, binary, binary} or {atom, binary}"
    validate_type!(file_path, story.navigation(), :list, msg)

    for nav <- story.navigation() do
      unless match_attr_type?(nav, {:tuple, 2}) do
        validate_type!(file_path, nav, {:tuple, 3}, msg)
      end

      {tab, name} = {elem(nav, 0), elem(nav, 1)}
      validate_type!(file_path, tab, :atom, msg)
      validate_type!(file_path, name, :string, msg)

      if tuple_size(nav) == 3 do
        validate_icon!(file_path, elem(nav, 2))
      end
    end
  end

  defp validate_example_extra_sources!(file_path, story) do
    msg = "example extra_sources must be a list of binary"
    validate_type!(file_path, story.extra_sources(), :list, msg)

    for source <- story.extra_sources() do
      validate_type!(file_path, source, :string, msg)
    end
  end

  defp validate_story_component!(file_path, story) do
    if story.storybook_type() == :live_component do
      validate_type!(file_path, story.component(), :atom, "story component must be a module")
    end
  end

  defp validate_component_function!(file_path, story) do
    if story.storybook_type() == :component do
      validate_type!(file_path, story.function(), :function, "story function must be a function")
    end
  end

  defp validate_component_aliases!(file_path, story) do
    msg = "story aliases must be a list of atoms"
    validate_type!(file_path, story.aliases, :list, msg)

    for alias_item <- story.aliases || [],
        do: validate_type!(file_path, alias_item, :atom, msg)
  end

  defp validate_component_imports!(file_path, story) do
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

  defp validate_component_container!(file_path, story) do
    case story.container() do
      c when c in ~w(nil div iframe)a -> :ok
      {:div, options} when is_list(options) -> :ok
      _ -> compile_error!(file_path, "story container must be :div, {:div, opts} or :iframe")
    end
  end

  defp validate_component_template!(file_path, story) do
    validate_type!(file_path, story.template, :string, "story template must be a binary")
  end

  defp validate_attribute_list_type!(file_path, attributes) do
    msg = "story attributes must be a list of %Attr{}"
    validate_type!(file_path, attributes, :list, msg)
    for attr <- attributes, do: validate_type!(file_path, attr, Attr, msg)
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

  @builtin_types [:string, :atom, :boolean, :integer, :float, :list, :map, :global]
  defp validate_attribute_types!(file_path, attributes) do
    for %Attr{id: attr_id, type: type} <- attributes do
      cond do
        type in [:any | @builtin_types] ->
          :ok

        is_atom(type) ->
          case Atom.to_string(type) do
            "Elixir." <> _ -> :ok
            _ -> bad_type!(attr_id, type, file_path)
          end

        true ->
          bad_type!(attr_id, type, file_path)
      end
    end
  end

  defp bad_type!(name, type, file) do
    compile_error!(file, """
    invalid type #{inspect(type)} for attr #{inspect(name)}.
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

  defp validate_attribute_required!(file_path, attributes) do
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

  defp validate_attribute_values!(file_path, attributes) do
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

  defp validate_attribute_global_options!(file_path, attributes) do
    for attr = %Attr{type: :global} <- attributes, opt <- ~w(required examples values)a do
      if Map.get(attr, opt) do
        compile_error!(file_path, "global attributes do not support the #{inspect(opt)} option")
      end
    end
  end

  defp validate_slot_list_type!(file_path, slots) do
    msg = "story slots must be a list of %Slot{}"
    validate_type!(file_path, slots, :list, msg)
    for slot <- slots, do: validate_type!(file_path, slot, Slot, msg)
  end

  defp validate_slot_ids!(file_path, slots) do
    Enum.reduce(slots, MapSet.new(), fn %Slot{id: slot_id}, acc ->
      validate_type!(
        file_path,
        slot_id,
        :atom,
        "id for slot #{inspect(slot_id)} must be an atom"
      )

      if MapSet.member?(acc, slot_id) do
        compile_error!(file_path, "duplicate slot id: #{inspect(slot_id)}")
      else
        MapSet.put(acc, slot_id)
      end
    end)
  end

  defp validate_slot_doc!(file_path, slots) do
    for %Slot{id: slot_id, doc: doc} <- slots do
      validate_type!(
        file_path,
        doc,
        :string,
        "doc for slot #{inspect(slot_id)} is not a binary"
      )
    end
  end

  defp validate_slot_required!(file_path, slots) do
    for %Slot{id: slot_id, required: required} <- slots do
      validate_type!(
        file_path,
        required,
        :boolean,
        "required for slot #{inspect(slot_id)} must be of type :boolean"
      )
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

    for %Variation{id: variation_id, attributes: attributes, slots: slots} <-
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
    end

    for %VariationGroup{id: group_id, variations: variations} <- variations,
        %Variation{id: variation_id, attributes: attributes, slots: slots} <- variations do
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
      for %Attr{id: attr_id, required: true} <- attributes,
          attr_id != :id,
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

  defp validate_variation_required_slots!(file_path, slots, variations) do
    required_slots = for %Slot{id: id, required: true} <- slots, into: MapSet.new(), do: id

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

  defp matching_slot?(:inner_block, slot) do
    not Regex.match?(~r|<:\w+.*|s, slot)
  end

  defp matching_slot?(slot_id, slot) do
    Regex.match?(~r|<:#{slot_id}.*</:#{slot_id}>|s, slot)
  end
end
