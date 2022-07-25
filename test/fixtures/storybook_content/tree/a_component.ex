defmodule TreeStorybook.AComponent do
  use PhxLiveStorybook.Entry, :component
  def component, do: AComponent
  def function, do: &AComponent.a_component/1

  def variations do
    [
      %Variation{id: :hello, attributes: %{label: "hello"}},
      %Variation{id: :world, attributes: %{label: "world"}}
    ]
  end
end
