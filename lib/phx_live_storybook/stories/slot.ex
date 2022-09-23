defmodule PhxLiveStorybook.Stories.Slot do
  @moduledoc """
  A slot is one of your component slots. Its structure mimics the LiveView 0.18.0 declarative
  assigns.

  Slots declaration will populate the Playground tab of your storybook, for each of your
  components.

  Supported keys:
  - `id`: the slot id (required). Should match your component slot name.
    Use the id `:inner_block` for your component default slot.
  - `doc`: a text documentation for this slot.
  - `required`: `true` if the attribute is mandatory.

  """
  @enforce_keys [:id]
  defstruct [:id, :doc, required: false]
end
