defmodule PhxLiveStorybook.EntryLiveTest do
  use ExUnit.Case, async: false
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
    assert_patched(view, "/storybook/a_component?tab=source&theme=default")
    assert html =~ "defmodule"
  end

  test "renders component, change theme and navigate", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_component")
    pid = view.pid

    view |> element("a.lsb-theme", "Colorful") |> render_click()
    assert_patched(view, "/storybook/a_component?tab=stories&theme=colorful")

    view |> element("a", "Source") |> render_click()
    assert_patched(view, "/storybook/a_component?tab=source&theme=colorful")

    html = view |> element("a", "Playground") |> render_click()
    assert_patched(view, "/storybook/a_component?tab=playground&theme=colorful")
    assert html =~ "a component: hello colorful"

    Phoenix.PubSub.subscribe(PhxLiveStorybook.PubSub, "playground")
    view |> element("a.lsb-theme", "Default") |> render_click()
    assert_receive {:new_theme, ^pid, :default}
    assert render(view) =~ "a component: hello default"
  end

  test "renders component entry and navigate to source tab with select", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_component")

    html =
      view
      |> element(".entry-nav-form select")
      |> render_change(%{navigation: %{tab: "source"}})

    assert_patched(view, "/storybook/a_component?tab=source&theme=default")
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
    assert_patched(view, "/storybook/b_page?tab=tab_2&theme=default")
    assert html =~ "B Page: tab_2"
  end

  test "navigate to unknown tab", %{conn: conn} do
    assert_raise PhxLiveStorybook.EntryTabNotFound, fn ->
      get(conn, "/storybook/a_component", tab: "unknown")
    end
  end

  test "navigate in sidebar", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/storybook/a_folder/aa_component")

    assert view |> element("#sidebar a", "A Component") |> render_click() =~
             "a component description"

    # reaching items under "A folder" which is open by default (cf. config.exs)
    assert view |> element("#sidebar a", "Aa Component") |> render_click() =~
             "Aa component description"

    assert view |> element("#sidebar a", "Ab Component") |> render_click() =~
             "Ab component description"

    # B folder is closed, items inside are not visible
    refute has_element?(view, "#sidebar a", "Ba Component")
    refute has_element?(view, "#sidebar a", "Bb Component")

    # opening "B folder" then reaching items inside
    element(view, "#sidebar div", "B folder") |> render_click()

    assert view |> element("#sidebar a", "Ba Component") |> render_click() =~
             "Ba component description"

    assert view |> element("#sidebar a", "Bb Component") |> render_click() =~
             "Bb component description"

    # closing "B folder"
    element(view, "#sidebar div", "B folder") |> render_click()
    refute has_element?(view, "#sidebar a", "Ba Component")
    refute has_element?(view, "#sidebar a", "Bb Component")
  end

  describe "search modal" do
    test "filters the search list based on user input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_page")

      assert has_element?(view, "#search-container a", "A Component")
      assert has_element?(view, "#search-container a", "Ab Component")

      view
      |> with_target("#search-container")
      |> render_change("search", %{"search" => %{"input" => "A Component"}})

      assert has_element?(view, "#search-container a", "A Component")
      refute has_element?(view, "#search-container a", "Ab Component")
    end

    test "navigates to a specified entry", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_page")

      view
      |> with_target("#search-container")
      |> render_change("navigate", %{"path" => "/storybook/a_component"})

      assert_patched(view, "/storybook/a_component")
    end
  end
end
