defmodule TreeStorybook.TemplateComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &TemplateComponent.template_component/1

  def template do
    """
    <div>
      <button id="set-foo" phx-click="set-story-assign/:story_id/label/foo">Set label to foo</button>
      <button id="set-bar" phx-click="set-story-assign/:story_id/label/bar">Set label to bar</button>
      <button id="toggle-status" phx-click="toggle-story-assign/:story_id/status">Toggle status</button>
      <button id="set-status-true" phx-click="set-story-assign/:story_id/status/true">Set status to true</button>
      <button id="set-status-false" phx-click="set-story-assign/:story_id/status/false">Set status to false</button>
      <.story/>
    </div>
    """
  end

  def attributes do
    [
      %Attr{
        id: :label,
        type: :string,
        doc: "component label",
        required: true
      },
      %Attr{
        id: :status,
        type: :boolean,
        doc: "component status",
        default: false
      }
    ]
  end

  def stories do
    [
      %Story{
        id: :hello,
        description: "Hello story",
        attributes: %{label: "hello"}
      },
      %Story{
        id: :world,
        description: "World story",
        attributes: %{label: "world"}
      }
    ]
  end
end
