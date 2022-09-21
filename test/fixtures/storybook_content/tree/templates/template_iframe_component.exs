defmodule TreeStorybook.TemplateIframeComponent do
  use PhxLiveStorybook.Story, :component
  def function, do: &TemplateComponent.template_component/1
  def container, do: :iframe

  def template do
    """
    <div>
      <button id="set-foo" phx-click={JS.push("assign", value: %{label: "foo"})}>Set label to foo</button>
      <button id="set-bar" phx-click={JS.push("assign", value: %{label: "bar"})}>Set label to bar</button>
      <button id="toggle-status" phx-click={JS.push("toggle", value: %{attr: :status})}>Toggle status</button>
      <button id="set-status-true" phx-click={JS.push("assign", value: %{status: true})}>Set status to true</button>
      <button id="set-status-false" phx-click={JS.push("assign", value: %{status: false})}>Set status to false</button>
      <.lsb-variation/>
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
