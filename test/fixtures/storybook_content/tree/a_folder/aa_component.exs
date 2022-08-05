defmodule TreeStorybook.AFolder.AaComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &AComponent.a_component/1
  def icon, do: "aa-icon"

  def description, do: "Aa component description"

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
            description: "World story",
            attributes: %{label: "world", index: 37}
          }
        ]
      }
    ]
  end
end
