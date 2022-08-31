defmodule TreeStorybook.Component do
  use PhxLiveStorybook.Entry, :component
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

  def stories do
    [
      %Story{
        id: :hello,
        description: "Hello story",
        attributes: %{label: "hello"}
      },
      %Story{
        id: :world,
        description: "World story",
        attributes: %{label: "world", index: 37}
      }
    ]
  end
end
