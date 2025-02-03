defmodule TreeStorybook.TemplateIframeComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &TemplateComponent.template_component/1
  def container, do: :iframe

  def template do
    """
    <div>
      <button class="btn" id="set-foo-:variation_id" phx-click={JS.push("psb-assign", value: %{label: "foo"})}>Set label to foo</button>
      <button class="btn" id="set-bar-:variation_id" phx-click={JS.push("psb-assign", value: %{label: "bar"})}>Set label to bar</button>
      <button class="btn" id="toggle-status-:variation_id" phx-click={JS.push("psb:toggle", value: %{attr: :status})}>Toggle status</button>
      <button class="btn" id="set-status-true-:variation_id" phx-click={JS.push("psb-assign", value: %{status: true})}>Set status to true</button>
      <button class="btn" id="set-status-false-:variation_id" phx-click={JS.push("psb-assign", value: %{status: false})}>Set status to false</button>
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
      },
      %Attr{
        id: :status,
        type: :boolean,
        doc: "component status",
        default: false
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :hello,
        description: "Hello variation",
        attributes: %{label: "hello"}
      },
      %Variation{
        id: :world,
        description: "World variation",
        attributes: %{label: "world"}
      }
    ]
  end
end
