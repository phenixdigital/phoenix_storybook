defmodule TreeStorybook.BComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: BComponent

  def description, do: "b component description"

  def stories do
    [
      %Story{
        id: :hello,
        description: "Hello story",
        attributes: %{label: "hello"}
      },
      %Story{
        id: :world,
        attributes: %{label: "world"},
        block: """
        <span>inner block</span>
        """
      }
    ]
  end
end
