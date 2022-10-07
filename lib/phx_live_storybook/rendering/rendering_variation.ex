defmodule PhxLiveStorybook.Rendering.RenderingVariation do
  @moduledoc false

  @enforce_keys [:id, :dom_id]
  defstruct [:id, :dom_id, attributes: [], slots: [], let: nil]
end
