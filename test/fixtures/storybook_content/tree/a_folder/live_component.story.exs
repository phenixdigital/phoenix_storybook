defmodule TreeStorybook.AFolder.LiveComponent do
  use PhoenixStorybook.Story, :live_component
  def component, do: LiveComponent

  def attributes do
    [
      %Attr{id: :label, type: :string, required: true}
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block}
    ]
  end

  def variations do
    [
      %VariationGroup{
        id: :group,
        variations: [
          %Variation{
            id: :hello,
            description: "Hello variation",
            attributes: %{label: "hello"},
            slots: ["<span>inner block</span>"]
          },
          %Variation{
            id: :world,
            attributes: %{label: "world"}
          }
        ]
      },
      %Variation{
        id: :default,
        attributes: %{label: "hello"},
        slots: ["<span>inner block</span>"]
      }
    ]
  end
end
