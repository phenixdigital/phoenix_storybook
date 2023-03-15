defmodule TreeStorybook.BFolder.Component do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1

  defmodule NestedStruct do
    defstruct [:id, :name]
  end
end
