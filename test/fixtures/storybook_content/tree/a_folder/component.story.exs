defmodule TreeStorybook.AFolder.Component do
  use PhxLiveStorybook.Story, :component
  def function, do: &Component.component/1
  def description, do: "Aa component description"

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
            description: "World variation",
            attributes: %{label: "world", index: 37}
          }
        ]
      },
      %Variation{
        id: :no_attributes
      }
    ]
  end
end
