defmodule TreeStorybook.Event.EventComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &EventComponent.component/1

  def attributes do
    [
      %Attr{
        id: :label,
        type: :string,
        doc: "event component label",
        required: true
      }
    ]
  end

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
