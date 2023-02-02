defmodule TreeStorybook.LiveComponent do
  use PhoenixStorybook.Story, :live_component
  def component, do: LiveComponent

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
        slots: ["<span>inner block</span>"]
      }
    ]
  end
end
