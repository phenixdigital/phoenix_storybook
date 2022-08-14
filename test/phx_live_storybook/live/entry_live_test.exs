defmodule PhxLiveStorybook.EntryLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.EntryLiveTestEndpoint
  @moduletag :capture_log

  setup do
    start_supervised!(PhxLiveStorybook.EntryLiveTestEndpoint)
    {:ok, conn: build_conn()}
  end

  test "embeds phx-socket information", %{conn: conn} do
    assert get(conn, "/storybook/a_component") |> html_response(200) =~ ~s|phx-socket="/live"|
  end

  test "home path redirects to first page", %{conn: conn} do
    assert get(conn, "/storybook") |> redirected_to() =~ "/storybook/a_page"
  end

  test "404 on unknown entry", %{conn: conn} do
    assert_raise PhxLiveStorybook.EntryNotFound, fn ->
      get(conn, "/storybook/wrong")
    end
  end

  test "renders component entry from path", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/a_component")
    assert html =~ "A Component"
    assert html =~ "a component description"
    assert html =~ "Hello story"
    assert html =~ "World story"
  end

  test "renders live component entry from path", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/b_component")
    assert html =~ "B Component"
    assert html =~ "b component description"
    assert html =~ "Hello story"
    assert html =~ "World"
  end

  test "renders nested component entry from path", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/a_folder/aa_component")
    assert html =~ "Aa Component"
    assert html =~ "Aa component description"
  end

  test "renders component entry and navigate to source tab", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_component")

    html = view |> element("a", "Source") |> render_click()
    assert_patched(view, "/storybook/a_component?tab=source")
    assert html =~ "defmodule"
  end

  test "renders component entry and navigate to source tab with select", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_component")

    html =
      view
      |> element(".entry-nav-form select")
      |> render_change(%{navigation: %{tab: "source"}})

    assert_patched(view, "/storybook/a_component?tab=source")
    assert html =~ "defmodule"
  end

  test "renders a page entry", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/storybook/a_page")
    assert html =~ "A Page"
    refute html =~ "entry-tabs"
  end

  test "renders a page entry with tabs", %{conn: conn} do
    {:ok, view, html} = live(conn, "/storybook/b_page")
    assert html =~ "B Page: tab_1"
    assert html =~ "entry-tabs"

    html = view |> element("a", "Tab 2") |> render_click()
    assert_patched(view, "/storybook/b_page?tab=tab_2")
    assert html =~ "B Page: tab_2"
  end

  test "navigate to unknown tab", %{conn: conn} do
    assert_raise PhxLiveStorybook.EntryTabNotFound, fn ->
      get(conn, "/storybook/a_component", tab: "unknown")
    end
  end

  test "navigate in sidebar", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_folder/aa_component")

    assert view |> element("a", "A Component") |> render_click() =~ "a component description"

    # reaching items under "A folder" which is open by default (cf. config.exs)
    assert view |> element("a", "Aa Component") |> render_click() =~ "Aa component description"
    assert view |> element("a", "Ab Component") |> render_click() =~ "Ab component description"

    # B folder is closed, items inside are not visible
    refute has_element?(view, "a", "Ba Component")
    refute has_element?(view, "a", "Bb Component")

    # opening "B folder" then reaching items inside
    element(view, "div", "B folder") |> render_click()

    assert view |> element("a", "Ba Component") |> render_click() =~ "Ba component description"
    assert view |> element("a", "Bb Component") |> render_click() =~ "Bb component description"

    # closing "B folder"
    element(view, "div", "B folder") |> render_click()
    refute has_element?(view, "a", "Ba Component")
    refute has_element?(view, "a", "Bb Component")
  end
end
