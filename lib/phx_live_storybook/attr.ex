defmodule PhxLiveStorybook.Attr do
  @moduledoc """
  An attr is one of your component attributes. Its structure mimics
  forthcoming LiveView 0.18.0 declarative assigns.

  Attributes declaration will populate the Playground tab of your storybook,
  for each of your components.

  Supported keys:
  - `id`: the attribute id (required). Should match to your component assign.
  - `type`: the attribute type (required). But be one of:
    * `:any` - any term
    * `:string` - any binary string
    * `:atom` - any atom
    * `:boolean` - any boolean
    * `:integer` - any integer
    * `:float` - any float
    * `:list` - a List of any arbitrary types
    * `:block` - a block (you can only declare one)
    * `:slots` - a list of slots
    * Any struct module
  - `required`: `true` if the attribute is mandatory.
  - `doc`: a text documentation for this attribute.
  - `default`: attribute default value.
  """
  @enforce_keys [:id, :type]
  defstruct [:id, :type, :doc, :default, :options, required: false]
end
