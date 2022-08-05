defmodule TreeStorybook.AFolder.AbComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: BComponent
  def description, do: "Ab component description"

  def stories do
    [
      %StoryGroup{
        id: :group,
        stories: [
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
      }
    ]
  end
end
