defmodule TreeStorybook.InvalidTemplateComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &TemplateComponent.template_component/1

  def template do
    """
    <div id=":variation_id">
      <.psb-variation/>
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

  def variations do
    [
      %Variation{
        id: :invalid_template_placeholder,
        template: ~s|<div class="variation-template"><.psb-variation-group/></div>|,
        attributes: %{label: "invalid template"}
      }
    ]
  end
end
