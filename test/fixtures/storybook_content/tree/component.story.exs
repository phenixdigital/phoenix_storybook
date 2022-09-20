defmodule TreeStorybook.Component do
  use PhxLiveStorybook.Story, :component
  def function, do: &Component.component/1

  def description, do: "component description"

  def attributes do
    [
      %Attr{
        id: :label,
        type: :string,
        doc: "component label",
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
      },
      %Variation{
        id: :world,
        description: "World variation",
        attributes: %{label: "world", index: 37}
      }
    ]
  end
end
