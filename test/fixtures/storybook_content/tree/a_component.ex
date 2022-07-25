defmodule TreeStorybook.AComponent do
  use PhxLiveStorybook.Entry, :component
  def component, do: AComponent
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
        attributes: %{label: "world"}
      }
    ]
  end
end
