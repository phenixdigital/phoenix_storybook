defmodule PhxLiveStorybook.PlaygroundLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.PlaygroundLiveTestEndpoint

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
    end
  end
end
