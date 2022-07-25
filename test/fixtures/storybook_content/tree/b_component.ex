defmodule TreeStorybook.BComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: BComponent

  def variations do
    [
      %Variation{id: :hello, attributes: %{label: "hello"}},
      %Variation{id: :world, attributes: %{label: "world"}}
    ]
  end
end
