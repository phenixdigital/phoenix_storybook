defmodule PhxLiveStorybook.Attr do
  @moduledoc """
  An attr is one of your component attributes. Its structure mimics the
  upcoming LiveView 0.18.0 declarative assigns.

  Attributes declaration will populate the Playground tab of your storybook,
  for each of your components.

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
    * `:block` - a block (you can only declare one)
    * `:slot` - a slot (you can declare more than one)
    * Any struct module
  - `required`: `true` if the attribute is mandatory.
  - `default`: attribute default value.
  - `examples` the list or range of examples suggested for the attribute
  - `values` the list or range of all possible examples for the attribute. Unlike examples, this option
  enforces validation of the default value against the given list.
  - `doc`: a text documentation for this attribute.

  """
  @enforce_keys [:id, :type]
  defstruct [:id, :type, :doc, :default, :examples, :values, required: false]
end
