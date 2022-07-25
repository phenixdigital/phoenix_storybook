defmodule TreeStorybook.BComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: BComponent

  def description, do: "b component description"

  def variations do
    [
      %Variation{
        id: :hello,
        description: "Hello variation",
        attributes: %{label: "hello"}
      },
      %Variation{
        id: :world,
        description: "World variation",
        attributes: %{label: "world"}
      }
    ]
  end
end
