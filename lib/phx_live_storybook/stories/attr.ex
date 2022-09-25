defmodule PhxLiveStorybook.Stories.Attr do
  @moduledoc """
  An attr is one of your component attributes. Its structure mimics the LiveView 0.18.0 declarative
  assigns.

  Attributes declaration will populate the Playground tab of your storybook, for each of your
  components.

  Supported keys:
  - `id`: the attribute id (required). Should match your component assign.
  - `type`: the attribute type (required). Must be one of:
    * `:any` - any term
    * `:string` - any binary string
    * `:atom` - any atom
    * `:boolean` - any boolean
    * `:integer` - any integer
    * `:float` - any float
    * `:map` - any map
    * `:list` - a List of any arbitrary types
    * `:global`- any common HTML attributes,
    * Any struct module
  - `required`: `true` if the attribute is mandatory.
  - `default`: attribute default value.
  - `examples` the list or range of examples suggested for the attribute
  - `values` the list or range of all possible examples for the attribute. Unlike examples, this
     option enforces validation of the default value against the given list.
  - `doc`: a text documentation for this attribute.
  """

  alias PhxLiveStorybook.Stories.Attr

  @enforce_keys [:id, :type]
  defstruct [:id, :type, :doc, :default, :examples, :values, required: false]

  @doc false
  def merge_attributes(mod_or_fun, story_attrs) do
    component_attrs = read_attributes(mod_or_fun)
    component_attrs_map = mod_or_fun |> read_attributes() |> attributes_map(:name)
    story_attrs_map = attributes_map(story_attrs, :id)
    attr_keys = Enum.uniq(Enum.map(component_attrs, & &1.name) ++ Enum.map(story_attrs, & &1.id))

    for attr_id <- attr_keys do
      component_attr = Map.get(component_attrs_map, attr_id)
      story_attr = Map.get(story_attrs_map, attr_id)
      build_attr(component_attr, story_attr)
    end
  end

  defp read_attributes(fun_or_mod)

  defp read_attributes(module) when is_atom(module) do
    attrs = get_in(module.__components__(), [:render, :attrs]) || []
    Enum.sort_by(attrs, & &1.line)
  end

  defp read_attributes(function) when is_function(function) do
    [module: module, name: name] = function |> Function.info() |> Keyword.take([:module, :name])
    attrs = get_in(module.__components__(), [name, :attrs]) || []
    Enum.sort_by(attrs, & &1.line)
  end

  defp attributes_map(attrs, key) do
    for attr <- attrs, into: %{}, do: {Map.get(attr, key), attr}
  end

  defp build_attr(nil, story_attribute = %Attr{}), do: story_attribute

  defp build_attr(attr, nil) do
    %Attr{
      id: attr.name,
      type: attr.type,
      required: attr[:required],
      default: get_in(attr, [:opts, :default]),
      values: get_in(attr, [:opts, :values]),
      examples: get_in(attr, [:opts, :examples]),
      doc: attr.doc
    }
  end

  defp build_attr(attr, story_attribute = %Attr{}) do
    %Attr{
      id: attr.name,
      type: merge_attr_key(story_attribute, attr, :type, nil),
      required: merge_attr_key(story_attribute, attr, :required, false),
      default: merge_attr_key(story_attribute, attr, :default, [:opts, :default], nil),
      values: merge_attr_key(story_attribute, attr, :values, [:opts, :values], nil),
      examples: merge_attr_key(story_attribute, attr, :examples, [:opts, :examples], nil),
      doc: merge_attr_key(story_attribute, attr, :doc, nil)
    }
  end

  defp merge_attr_key(story_attribute = %Attr{}, attr, key, attr_keys \\ nil, default) do
    attr_keys = if is_nil(attr_keys), do: [key], else: attr_keys

    case Map.get(story_attribute, key) do
      falsy when falsy in [nil, false] -> get_in(attr, attr_keys) || default
      val -> val
    end
  end
end
