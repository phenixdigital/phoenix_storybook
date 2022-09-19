defmodule TreeStorybook.LiveComponent do
  use PhxLiveStorybook.Story, :live_component
  def component, do: LiveComponent

  def name, do: "Live Component (root)"
  def description, do: "live component description"
  def container, do: :iframe

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
