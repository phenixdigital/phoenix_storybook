defmodule TreeStorybook.TemplateComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &TemplateComponent.template_component/1

  def template do
    """
    <div id=":story_id" class="template-div">
      <button id="set-foo" phx-click="set-story-assign/:story_id/label/foo">Set label to foo</button>
      <button id="set-bar" phx-click="set-story-assign/:story_id/label/bar">Set label to bar</button>
      <button id="toggle-status" phx-click="toggle-story-assign/:story_id/status">Toggle status</button>
      <button id="set-status-true" phx-click="set-story-assign/:story_id/status/true">Set status to true</button>
      <button id="set-status-false" phx-click="set-story-assign/:story_id/status/false">Set status to false</button>
      <.lsb-story/>
    </div>
    """
  end

  def attributes do
    [
      %Attr{
        id: :label,
        type: :string,
        doc: "component label"
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
      },
      %StoryGroup{
        id: :group,
        stories: [
          %Story{
            id: :one,
            attributes: %{label: "one"}
          },
          %Story{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %Story{
        id: :story_template,
        template: ~s|<div class="story-template"><.lsb-story/></div>|,
        attributes: %{label: "story template"}
      },
      %Story{
        id: :no_template,
        template: false,
        attributes: %{label: "story without template"}
      },
      %Story{
        id: :no_placeholder,
        template: "<div></div>",
        attributes: %{label: ""}
      },
      %StoryGroup{
        id: :group_template,
        template: ~s|<div class="group-template"><.lsb-story/></div>|,
        stories: [
          %Story{
            id: :one,
            attributes: %{label: "one"}
          },
          %Story{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %StoryGroup{
        id: :group_template_single,
        template: ~s|<div class="group-template"><.lsb-story-group/></div>|,
        stories: [
          %Story{
            id: :one,
            attributes: %{label: "one"}
          },
          %Story{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %StoryGroup{
        id: :no_placeholder_group,
        template: "<div></div>",
        stories: [
          %Story{
            id: :one,
            attributes: %{label: "one"}
          },
          %Story{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %Story{
        id: :template_attributes,
        template: ~s(<.lsb-story label="from_template" status={true}/>)
      }
    ]
  end
end
