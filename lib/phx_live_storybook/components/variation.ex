defmodule PhxLiveStorybook.Components.Variation do
  @enforce_keys [:id, :attributes]
  defstruct [:id, :description, :attributes, :slots, :block]
end
