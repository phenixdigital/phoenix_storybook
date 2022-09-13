defmodule PhxLiveStorybook.PlaygroundLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.PlaygroundLiveTestEndpoint
  @moduletag :capture_log

  setup do
    start_supervised!(PhxLiveStorybook.PlaygroundLiveTestEndpoint)
    {:ok, conn: build_conn()}
  end

  describe "simple component with one field" do
    test "renders playground", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"
    end

    test "playground preview is updated as form is changed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")

      view
      |> form("#tree_storybook_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "renders playground code a simple component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "hello"
    end

    test "playground code is updated as form is changed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      view |> element("a", "Code") |> render_click()

      view
      |> form("#tree_storybook_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("pre") |> render() =~ "world"

      view |> element("a", "Preview") |> render_click()
      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "we can switch to another story from the playground", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      view
      |> element("#story-selection-form_story_id")
      |> render_change(%{story: %{story_id: "world"}})

      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "we can switch to another story group from the playground", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/live_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      view
      |> element("#story-selection-form_story_id")
      |> render_change(%{story: %{story_id: "default"}})

      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"
    end
  end

  describe "component in an iframe" do
    test "renders the playground preview iframe", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/live_component?tab=playground")
      assert html =~ ~S|<iframe id="tree_storybook_live_component-playground-preview"|
    end
  end

  describe "empty playground" do
    test "with no stories, it does not crash", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/component?tab=playground")
      assert html =~ "Component"
    end

    test "with no attributes, it prints a placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/component?tab=playground")

      assert html =~
               ~r|<p>In order to use playground, you must define attributes in your.*Component.*entry\.</p>|
    end
  end

  describe "component with all kinds of data types" do
    test "it shows the component preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")

      assert view |> element("#playground-preview-live") |> render() =~
               "all_types_component: default label"
    end

    test "it show the component code", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")

      view |> element("a", "Code") |> render_click()

      assert view |> element("#playground-preview-live") |> render() =~
               "all_types_component: default label"

      assert view |> element("pre.highlight") |> render() =~ ".all_types_component"
    end

    test "component can be updated with a toggle switch", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "toggle: false"
      view |> element("button[role=switch]") |> render_click()
      assert view |> element("#playground-preview-live") |> render() =~ "toggle: true"
    end

    test "component can be updated with a new integer value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "index_i: 42"

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{index_i: "37"}
      })
      |> render_change()

      assert view |> element("#playground-preview-live") |> render() =~ "index_i: 37"
    end

    test "component can be updated with a new float value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "index_f: 37.2"

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{index_f: "42.1"}
      })
      |> render_change()

      assert view |> element("#playground-preview-live") |> render() =~ "index_f: 42.1"
    end

    test "component can be updated with a invalid value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "index_i: 42"

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{index_i: "wrong"}
      })
      |> render_change()

      assert view |> element("#playground-preview-live") |> render() =~ "index_i: wrong"
    end

    test "component can be updated by selecting an option", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{option: "opt3"}
      })
      |> render_change()

      assert view |> element("#playground-preview-live") |> render() =~ "option: opt3"
    end

    test "required label is still defined in code when empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      view |> element("a", "Code") |> render_click()

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{label: ""}
      })
      |> render_change()

      assert view |> element("pre.highlight") |> render() =~ "label"
    end
  end

  describe "live_component playground" do
    test "it shows the component preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/live_component?tab=playground")

      html = view |> element("#playground-preview-live") |> render()
      assert html =~ "component: hello"
      assert html =~ "inner block"
    end

    test "it shows the component code", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/live_component?tab=playground")
      view |> element("a", "Code") |> render_click()
      assert view |> element("pre.highlight") |> render() =~ "hello"
    end
  end

  describe "component preview crash handling" do
    test "an error message is displayed when component crashes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      Process.flag(:trap_exit, true)

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{label: "raise"}
      })
      |> render_change()

      assert_receive {:EXIT, _, {%RuntimeError{message: "booooom!"}, _}}
    end
  end

  describe "template component in playground" do
    test "component rendering is updated as template buttons are clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component?tab=playground")
      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")
      assert render(playground_element) =~ "template_component: hello"

      playground_preview_view |> element("#set-foo") |> render_click()
      assert render(playground_element) =~ "template_component: foo / status: false"

      playground_preview_view |> element("#set-bar") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view |> element("#toggle-status") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: true"

      playground_preview_view |> element("#toggle-status") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view |> element("#set-status-true") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: true"

      playground_preview_view |> element("#set-status-false") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: false"
    end

    test "playground form is in sync with stories assigns", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component?tab=playground")
      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~ "template_component: hello"
      playground_preview_view |> element("#set-foo") |> render_click()
      assert render(playground_element) =~ "template_component: foo / status: false"

      form_selector = "#tree_storybook_template_component-playground-form"
      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert get_element_attribute(view, form_label_selector, "value") == "foo"

      view |> form(form_selector, %{playground: %{label: "bar"}}) |> render_change()
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view |> element("#toggle-status") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: true"

      assert get_element_attribute(view, form_toggle_selector, "value") == "true"
      view |> form(form_selector, %{playground: %{status: true}}) |> render_change()
      assert render(playground_element) =~ "template_component: bar / status: true"
    end

    test "playground form is in sync with a group of stories", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/storybook/templates/template_component?tab=playground&story_id=group")

      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~ "template_component: one"
      assert render(playground_element) =~ "template_component: two"
      playground_preview_view |> element("#one #set-foo") |> render_click()
      assert render(playground_element) =~ "template_component: foo / status: false"
      assert render(playground_element) =~ "template_component: two / status: false"

      form_selector = "#tree_storybook_template_component-playground-form"
      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert get_element_attribute(view, form_label_selector, "value") == "[Multiple values]"

      playground_preview_view |> element("#two #set-foo") |> render_click()
      assert render(playground_element) =~ "template_component: foo / status: false"
      refute render(playground_element) =~ "template_component: bar / status: false"

      view |> form(form_selector, %{playground: %{label: "bar"}}) |> render_change()
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view |> element("#one #toggle-status") |> render_click()
      assert render(playground_element) =~ "template_component: bar / status: true"
      assert render(playground_element) =~ "template_component: bar / status: false"

      assert get_element_attribute(view, form_toggle_selector, "value") == "[Multiple values]"
      playground_preview_view |> element("#two #toggle-status") |> render_click()
      view |> form(form_selector, %{playground: %{status: "true"}}) |> render_change()
      assert render(playground_element) =~ "template_component: bar / status: true"
      refute render(playground_element) =~ "template_component: bar / status: false"
    end

    test "playground with template values", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&story_id=template_attributes"
        )

      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~
               "<span>template_component: from_template / status: true</span>"

      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert view |> element(form_label_selector) |> render() |> Floki.attribute("disabled") ==
               ["disabled"]

      assert view |> element(form_toggle_selector) |> render() |> Floki.attribute("disabled") ==
               ["disabled"]
    end

    test "playground with a story_group, and an empty template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&story_id=no_placeholder_group"
        )

      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")
      assert render(playground_element) =~ "<div></div>"
    end

    test "component code is visible", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component?tab=playground")

      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "hello"
    end

    test "component code is visible for a story_group with a template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&story_id=group_template"
        )

      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "one"
    end

    test "component code is visible for a story_group with a single template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&story_id=group_template_single"
        )

      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "one"
    end
  end

  defp get_element_attribute(view, selector, attribute) do
    view
    |> element(selector)
    |> render()
    |> Floki.parse_fragment!()
    |> Floki.attribute(attribute)
    |> Enum.at(0)
  end
end
