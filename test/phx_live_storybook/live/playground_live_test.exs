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
      {:ok, view, _html} = live(conn, "/storybook/a_component?tab=playground")
      assert view |> element("#playground-preview-live-0") |> render() =~ "a component: hello"
    end

    test "playground preview is updated as form is changed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_component?tab=playground")

      view
      |> form("#tree_storybook_a_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("#playground-preview-live-1") |> render() =~ "a component: world"
    end

    test "renders playground code a simple component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_component?tab=playground")
      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "hello"
    end

    test "playground code is updated as form is changed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_component?tab=playground")
      view |> element("a", "Code") |> render_click()

      view
      |> form("#tree_storybook_a_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("pre") |> render() =~ "world"

      view |> element("a", "Preview") |> render_click()
      assert view |> element("#playground-preview-live-1") |> render() =~ "a component: world"
    end
  end

  describe "component in an iframe" do
    test "renders the playground preview iframe", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_component?tab=playground")
      assert html =~ ~S|<iframe id="tree_storybook_b_component-playground-preview"|
    end
  end

  describe "empty playground" do
    test "with no stories, it does not crash", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/ba_component?tab=playground")
      assert html =~ "Ba Component"
    end

    test "with no attributes, it prints a placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/ba_component?tab=playground")

      assert html =~
               ~r|<p>In order to use playground, you must define attributes in your.*Ba Component.*entry\.</p>|
    end
  end

  describe "component with all kinds of data types" do
    test "it shows the component preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")

      assert view |> element("#playground-preview-live-0") |> render() =~
               "c component: default label"
    end

    test "it show the component code", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")

      view |> element("a", "Code") |> render_click()

      assert view |> element("#playground-preview-live-0") |> render() =~
               "c component: default label"

      assert view |> element("pre.highlight") |> render() =~ ".c_component"
    end

    test "component can be updated with a toggle switch", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")
      assert view |> element("#playground-preview-live-0") |> render() =~ "toggle: false"
      view |> element("button[role=switch]") |> render_click()
      assert view |> element("#playground-preview-live-1") |> render() =~ "toggle: true"
    end

    test "component can be updated by selecting an option", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")

      view
      |> form("#tree_storybook_b_folder_bb_component-playground-form", %{
        playground: %{option: "opt3"}
      })
      |> render_change()

      assert view |> element("#playground-preview-live-1") |> render() =~ "option: opt3"
    end

    test "required label is still defined in code when empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")

      view |> element("a", "Code") |> render_click()

      view
      |> form("#tree_storybook_b_folder_bb_component-playground-form", %{
        playground: %{label: ""}
      })
      |> render_change()

      assert view |> element("pre.highlight") |> render() =~ "label"
    end
  end

  describe "live_component playground" do
    test "it shows the component preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/ab_component?tab=playground")

      html = view |> element("#playground-preview-live-0") |> render()
      assert html =~ "b component: hello"
      assert html =~ "inner block"
    end

    test "it shows the component code", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/ab_component?tab=playground")
      view |> element("a", "Code") |> render_click()
      assert view |> element("pre.highlight") |> render() =~ "hello"
    end
  end

  describe "component preview crash handling" do
    test "an error message is displayed when component crashes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/bb_component?tab=playground")

      Process.flag(:trap_exit, true)

      view
      |> form("#tree_storybook_b_folder_bb_component-playground-form", %{
        playground: %{label: "raise"}
      })
      |> render_change()

      assert_receive {:EXIT, _, {%RuntimeError{message: "booooom!"}, _}}
    end
  end
end
