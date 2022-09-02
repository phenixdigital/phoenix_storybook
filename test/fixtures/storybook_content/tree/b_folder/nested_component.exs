defmodule TreeStorybook.BFolder.NestedComponent do
  use PhxLiveStorybook.Entry, :component

  def function, do: &NestedComponent.nested_component/1

  def imports do
    [{NestedComponent, nested: 1}]
  end

  def stories do
    [
      %Story{
        id: :default,
        block: """
        <.nested>hello</.nested>
        <.nested>world</.nested>
        """
      }
    ]
  end
end
