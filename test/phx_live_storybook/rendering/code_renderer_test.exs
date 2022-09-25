defmodule PhxLiveStorybook.Rendering.CodeRendererTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.TreeStorybook
  alias PhxLiveStorybook.Rendering.CodeRenderer
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  setup_all do
    [
      component: TreeStorybook.load_story("/component") |> elem(1),
      live_component: TreeStorybook.load_story("/live_component") |> elem(1),
      afolder_component: TreeStorybook.load_story("/a_folder/component") |> elem(1),
      afolder_live_component: TreeStorybook.load_story("/a_folder/live_component") |> elem(1),
      template_component: TreeStorybook.load_story("/templates/template_component") |> elem(1),
      all_types_component: TreeStorybook.load_story("/b_folder/all_types_component") |> elem(1)
    ]
  end

  describe "render_variation_code/2" do
    test "it should return HEEX for each component/variation couple", %{
      component: component,
      live_component: live_component
    } do
      code = render_variation_code(component, :hello)
      assert code =~ ~s|<.component label="hello"/>|

      code = render_variation_code(component, :world)
      assert code =~ ~s|<.component index={37} label="world"/>|

      code = render_variation_code(live_component, :hello)
      assert code =~ ~s|<.live_component module={LiveComponent} label="hello"/>|

      code = render_variation_code(live_component, :world)

      assert code =~ """
             <.live_component module={LiveComponent} label="world">
               <span>inner block</span>
             </.live_component>
             """
    end

    test "it also works for a variation group", %{
      afolder_component: component,
      afolder_live_component: live_component
    } do
      code = render_variation_code(component, :group)

      assert code =~ """
             <.component label="hello"/>
             <.component index={37} label="world"/>
             """

      code = render_variation_code(live_component, :group)

      assert code =~ """
             <.live_component module={LiveComponent} label="hello">
               <span>inner block</span>
             </.live_component>
             <.live_component module={LiveComponent} label="world"/>
             """
    end

    test "it is working with a variation without any attributes", %{afolder_component: component} do
      code = render_variation_code(component, :no_attributes)
      assert code =~ ~s|<.component/>|
    end

    test "it is working with an inner_block requiring a let attribute" do
      {:ok, component} = TreeStorybook.load_story("/let/let_component")
      code = render_variation_code(component, :default)

      assert code =~ """
             <.let_component let={entry} stories={["foo", "bar", "qix"]}>
               **<%= entry %>**
             </.let_component>
             """
    end

    test "it is working with an inner_block requiring a let attribute, in a live component" do
      {:ok, component} = TreeStorybook.load_story("/let/let_live_component")
      code = render_variation_code(component, :default)

      assert code =~ """
             <.live_component module={LetLiveComponent} let={entry} stories={["foo", "bar", "qix"]}>
               **<%= entry %>**
             </.live_component>
             """
    end

    test "it is working with a template component" do
      {:ok, component} = TreeStorybook.load_story("/templates/template_component")
      code = render_variation_code(component, :hello)

      assert code =~ """
             <div id=":variation_id" class="template-div">
               <button id="set-foo" phx-click={JS.push("assign", value: %{label: "foo"})}>Set label to foo</button>
               <button id="set-bar" phx-click={JS.push("assign", value: %{label: "bar"})}>Set label to bar</button>
               <button id="toggle-status" phx-click={JS.push("toggle", value: %{attr: :status})}>Toggle status</button>
               <button id="set-status-true" phx-click={JS.push("assign", value: %{status: true})}>Set status to true</button>
               <button id="set-status-false" phx-click={JS.push("assign", value: %{status: false})}>Set status to false</button>
               <.template_component label="hello"/>
             </div>
             """
    end

    test "it prints aliases struct names" do
      {:ok, component} = TreeStorybook.load_story("/b_folder/all_types_component")
      code = render_variation_code(component, :with_struct)

      assert code =~ """
             <.all_types_component label="foo" struct={%Struct{name: "bar"}}>
               <p>inner block</p>
             </.all_types_component>
             """
    end

    test "its renders properly global attributes", %{all_types_component: component} do
      code = render_variation_code(component, :default)

      assert code =~ """
             <.all_types_component label="default label" foo="bar" data-bar={42} toggle={false}>
               <p>will be displayed in inner block</p>
               <:slot_thing>slot 1</:slot_thing>
               <:slot_thing>slot 2</:slot_thing>
               <:other_slot>not displayed</:other_slot>
             </.all_types_component>
             """
    end
  end

  describe "render_component_source/2" do
    test "it renders a component source", %{component: component} do
      source = CodeRenderer.render_component_source(component) |> rendered_to_string()
      assert source =~ ~r/<pre.*lsb highlight.*\/pre>/s
    end

    test "it renders a live component source", %{live_component: component} do
      source = CodeRenderer.render_component_source(component) |> rendered_to_string()
      assert source =~ ~r/<pre.*lsb highlight.*\/pre>/s
    end
  end

  defp render_variation_code(story, variation_id) do
    CodeRenderer.render_variation_code(story, variation_id, format: false)
    |> rendered_to_string()
  end
end
