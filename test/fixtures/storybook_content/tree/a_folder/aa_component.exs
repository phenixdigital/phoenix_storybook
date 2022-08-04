defmodule TreeStorybook.AFolder.AaComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &AComponent.a_component/1
  def icon, do: "aa-icon"

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
      }
    ]
  end
end
