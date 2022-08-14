defmodule TreeStorybook.BFolder.BaComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &AComponent.a_component/1

  def description, do: "Ba component description"
end
