defmodule TreeStorybook.InvalidTemplateComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &TemplateComponent.template_component/1

  def template do
    """
    <div id=":story_id">
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
      }
    ]
  end

  def stories do
    [
      %Story{
        id: :invalid_template_placeholder,
        template: ~s|<div class="story-template"><.story-group/></div>|,
        attributes: %{label: "invalid template"}
      }
    ]
  end
end
