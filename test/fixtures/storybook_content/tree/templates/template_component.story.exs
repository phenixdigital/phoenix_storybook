defmodule TreeStorybook.TemplateComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &TemplateComponent.template_component/1

  def template do
    """
    <div id=":variation_id" class="template-div">
      <button id="set-foo" phx-click={JS.push("assign", value: %{label: "foo"})}>Set label to foo</button>
      <button id="set-bar" phx-click={JS.push("assign", value: %{label: "bar"})}>Set label to bar</button>
      <button id="toggle-status" phx-click={JS.push("toggle", value: %{attr: :status})}>Toggle status</button>
      <button id="set-status-true" phx-click={JS.push("assign", value: %{status: true})}>Set status to true</button>
      <button id="set-status-false" phx-click={JS.push("assign", value: %{status: false})}>Set status to false</button>
      <.psb-variation/>
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
      },
      %VariationGroup{
        id: :group,
        variations: [
          %Variation{
            id: :one,
            attributes: %{label: "one"}
          },
          %Variation{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %Variation{
        id: :variation_template,
        template: ~s|<div class="variation-template"><.psb-variation/></div>|,
        attributes: %{label: "variation template"}
      },
      %Variation{
        id: :no_template,
        template: false,
        attributes: %{label: "variation without template"}
      },
      %Variation{
        id: :hidden_template,
        template: ~s|<div class="variation-template" psb-code-hidden><.psb-variation/></div>|,
        attributes: %{label: "variation hidden template"}
      },
      %Variation{
        id: :no_placeholder,
        template: "<div></div>",
        attributes: %{label: ""}
      },
      %VariationGroup{
        id: :group_template,
        template: """
        <div class="group-template">
          <.psb-variation/>
        </div>
        """,
        variations: [
          %Variation{
            id: :one,
            attributes: %{label: "one"}
          },
          %Variation{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %VariationGroup{
        id: :group_template_single,
        template: """
        <div class="group-template">
          <.psb-variation-group/>
        </div>
        """,
        variations: [
          %Variation{
            id: :one,
            attributes: %{label: "one"}
          },
          %Variation{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %VariationGroup{
        id: :group_template_hidden,
        template: """
        <div class="group-template" psb-code-hidden>
          <.psb-variation-group/>
        </div>
        """,
        variations: [
          %Variation{
            id: :one,
            attributes: %{label: "one"}
          },
          %Variation{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %VariationGroup{
        id: :no_placeholder_group,
        template: "<div></div>",
        variations: [
          %Variation{
            id: :one,
            attributes: %{label: "one"}
          },
          %Variation{
            id: :two,
            attributes: %{label: "two"}
          }
        ]
      },
      %Variation{
        id: :template_attributes,
        template: ~s(<.psb-variation label="from_template" status={true}/>)
      }
    ]
  end
end
