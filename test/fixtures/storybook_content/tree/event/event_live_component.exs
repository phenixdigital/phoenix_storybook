defmodule TreeStorybook.Event.EventLiveComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: EventLiveComponent

  def name, do: "Live Event Component (root)"
  def description, do: "event live component description"

  def stories do
    [
      %Story{
        id: :hello,
        description: "Hello story",
        attributes: %{label: "hello"}
      }
    ]
  end
end
