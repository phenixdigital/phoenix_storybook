defmodule PhxLiveStorybook.Rendering.RenderingVariation do
  @moduledoc false

  @enforce_keys [:id]
  defstruct [:id, attributes: [], slots: [], let: nil]
end
