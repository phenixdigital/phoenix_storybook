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
        attributes: %{label: "world"},
        block: """
        <span>inner block</span>
        """
      }
    ]
  end
end
