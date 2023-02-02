defmodule TreeStorybook.Event.EventLiveComponent do
  use PhoenixStorybook.Story, :live_component
  def component, do: EventLiveComponent

  def variations do
    [
      %Variation{
        id: :hello,
        description: "Hello variation",
        attributes: %{label: "hello"}
      }
    ]
  end
end
