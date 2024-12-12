defmodule PhoenixStorybook.VisualTestLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixStorybook.VisualTestLiveEndpoint

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  test "renders a component", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/visual_tests/component")
    assert html =~ ~r|component:\s*hello\s*default|
  end

  test "renders an iframe component", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/visual_tests/live_component")
    assert html =~ "<iframe"
  end

  test "renders a component range", %{conn: conn} do
    {:ok, _view, html} = conn |> get("/storybook/visual_tests", start: "a", end: "e") |> live()
    assert html =~ "component: hello default"
    assert html =~ "inner block"
    refute html =~ "A Page"
    assert html |> Floki.parse_document!() |> Floki.find("h1") |> length() == 5
  end

  test "renders another component range", %{conn: conn} do
    {:ok, _view, html} = conn |> get("/storybook/visual_tests", start: "a", end: "z") |> live()
    assert html |> Floki.parse_document!() |> Floki.find("h1") |> length() == 19
  end

  test "exclude components from the range", %{conn: conn} do
    {:ok, _view, html} =
      conn
      |> get("/storybook/visual_tests",
        start: "a",
        end: "z",
        excludes: "Nested Component,With Id Component"
      )
      |> live()

    assert html |> Floki.parse_document!() |> Floki.find("h1") |> length() == 17
  end

  @tag :capture_log
  test "404 on unknown story path", %{conn: conn} do
    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      live(conn, "/storybook/visual_tests/unknown")
    end
  end

  @tag :capture_log
  test "404 on page story path", %{conn: conn} do
    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      live(conn, "/storybook/visual_tests/a_page")
    end
  end

  @tag :capture_log
  test "404 on example story path", %{conn: conn} do
    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      live(conn, "/storybook/visual_tests/examples/example")
    end
  end
end
