defmodule TreeStorybook.BFolder.Component do
  use PhxLiveStorybook.Story, :component
  def function, do: &Component.component/1
  def name, do: "Component (b_folder)"
  def description, do: "component description"
end
