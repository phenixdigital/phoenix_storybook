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
      html = render(playground_element)
      assert html =~ "template_component: hello"

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
  end
end
