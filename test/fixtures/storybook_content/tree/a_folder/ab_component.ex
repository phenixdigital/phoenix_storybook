defmodule TreeStorybook.AFolder.AbComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: BComponent

  def description, do: "Ab component description"

  def variations do
    [
      %VariationGroup{
        id: :group,
        variations: [
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
      }
    ]
  end
end
