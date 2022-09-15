defmodule TreeStorybook.AFolder.Component do
  use PhxLiveStorybook.Entry, :component
  def function, do: &Component.component/1
  def icon, do: "aa-icon"

  def name, do: "Component (a_folder)"
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
      },
      %Story{
        id: :no_attributes
      }
    ]
  end
end
