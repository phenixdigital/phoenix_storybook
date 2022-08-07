defmodule PhxLiveStorybook.Attr do
  @moduledoc """
  An attr is one of your component attributes. Itss structure mimics
  forthcoming LiveView 0.18.0 declarative assigns.

  Attributes declaration will populate the Documentation tab of your
  storybook, for each of your components.

  Supported keys:
  - `id`: the attribute id (required). Should match to your component assign.
  - `type`: the attribute type (required).
  - `required`: `true` if the attribute is mandatory.
  - `doc`: a text documentation for this attribute.
  - `default`: attribute default value.
  - `init`: if you want to init the playground input with a value different
    than the `default` one.
  """
  @enforce_keys [:id, :type]
  defstruct [:id, :type, :required, :doc, :default, :init, :options]
end
