defmodule TreeStorybook.AFolder.LiveComponent do
  use PhxLiveStorybook.Story, :live_component
  def component, do: LiveComponent
  def description, do: "Live component description"

  def attributes do
    [
      %Attr{id: :label, type: :string, required: true},
      %Attr{id: :block, type: :block}
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
            block: """
            <span>inner block</span>
            """
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
        block: """
        <span>inner block</span>
        """
      }
    ]
  end
end
