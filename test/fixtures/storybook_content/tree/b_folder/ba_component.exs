defmodule TreeStorybook.BFolder.BaComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &Component.component/1

  def description, do: "Ba component description"
end
