defmodule TreeStorybook.AComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &AComponent.a_component/1

  def description, do: "a component description"

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
