defmodule TreeStorybook.AFolder.AbComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: LiveComponent
  def description, do: "Ab component description"

  def attributes do
    [
      %Attr{id: :label, type: :string, required: true},
      %Attr{id: :block, type: :block}
    ]
  end

  def stories do
    [
      %StoryGroup{
        id: :group,
        stories: [
          %Story{
            id: :hello,
            description: "Hello story",
            attributes: %{label: "hello"},
            block: """
            <span>inner block</span>
            """
          },
          %Story{
            id: :world,
            attributes: %{label: "world"}
          }
        ]
      },
      %Story{
        id: :default,
        attributes: %{label: "hello"},
        block: """
        <span>inner block</span>
        """
      }
    ]
  end
end
