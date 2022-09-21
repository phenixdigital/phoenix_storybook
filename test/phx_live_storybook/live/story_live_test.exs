defmodule PhxLiveStorybook.StoryLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.StoryLiveTestEndpoint
  @moduletag :capture_log

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  test "embeds phx-socket information", %{conn: conn} do
    assert get(conn, "/storybook/component") |> html_response(200) =~ ~s|phx-socket="/live"|
  end

  describe "navigation" do
    test "home path redirects to first page", %{conn: conn} do
      assert get(conn, "/storybook") |> redirected_to() =~ "/storybook/a_page"
    end

    test "404 on unknown story", %{conn: conn} do
      assert_raise PhxLiveStorybook.StoryNotFound, fn ->
        get(conn, "/storybook/wrong")
      end
    end

    test "navigate in sidebar", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/component")

      assert view |> element("#sidebar a", "Live Component (root)") |> render_click() =~
               "live component description"

      # reaching items under "A folder" which is open by default (cf. config.exs)
      assert view |> element("#sidebar a", "Live Component (a_folder)") |> render_click() =~
               "Live component description"

      # B folder is closed, items inside are not visible
      refute has_element?(view, "#sidebar a", "AllTypesComponent (b_folder)")

      # opening "B folder" then reaching items inside
      element(view, "#sidebar div", "B folder") |> render_click()

      assert view |> element("#sidebar a", "AllTypesComponent (b_folder)") |> render_click() =~
               "All types component description"

      # closing "B folder"
      element(view, "#sidebar div", "B folder") |> render_click()
      refute has_element?(view, "#sidebar a", "AllTypesComponent (b_folder)")
    end

    test "navigate to unknown tab", %{conn: conn} do
      assert_raise PhxLiveStorybook.StoryTabNotFound, fn ->
        get(conn, "/storybook/component", tab: "unknown")
      end
    end
  end

  describe "variation rendering" do
    test "renders component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/component")
      assert html =~ "Component"
      assert html =~ "component description"
      assert html =~ "Hello variation"
      assert html =~ "World variation"
    end

    test "renders live component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/live_component")
      assert html =~ "Live Component"
      assert html =~ "live component description"
      assert html =~ "Hello variation"
      assert html =~ "World"
    end

    test "renders nested component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/a_folder/component")
      assert html =~ "Component"
      assert html =~ "component description"
    end

    test "renders component story and navigate to source tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      html = view |> element("a", "Source") |> render_click()
      assert_patched(view, "/storybook/component?tab=source&theme=default&variation_id=hello")
      assert html =~ "defmodule"
    end

    test "renders component, change theme and navigate", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      view |> element("a.lsb-theme", "Colorful") |> render_click()

      assert_patched(
        view,
        "/storybook/component?tab=variations&theme=colorful&variation_id=hello"
      )

      view |> element("a", "Source") |> render_click()
      assert_patched(view, "/storybook/component?tab=source&theme=colorful&variation_id=hello")

      html = view |> element("a", "Playground") |> render_click()

      assert_patched(
        view,
        "/storybook/component?tab=playground&theme=colorful&variation_id=hello"
      )

      assert html =~ "component: hello colorful"

      Phoenix.PubSub.subscribe(PhxLiveStorybook.PubSub, "playground-#{inspect(view.pid)}")
      view |> element("a.lsb-theme", "Default") |> render_click()
      assert_receive {:set_theme, :default}
      assert render(view) =~ "component: hello default"
    end

    test "renders component story and navigate to source tab with select", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      html =
        view
        |> element(".story-nav-form select")
        |> render_change(%{navigation: %{tab: "source"}})

      assert_patched(view, "/storybook/component?tab=source&theme=default&variation_id=hello")
      assert html =~ "defmodule"
    end

    test "component variation with template", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component")
      hello_element = element(view, "#hello .lsb-sandbox")
      world_element = element(view, "#world .lsb-sandbox")

      assert render(hello_element) =~ "template_component: hello / status: false"
      assert render(world_element) =~ "template_component: world / status: false"

      view |> element("#hello #set-foo") |> render_click()
      assert render(hello_element) =~ "template_component: foo / status: false"

      view |> element("#hello #set-bar") |> render_click()
      assert render(hello_element) =~ "template_component: bar / status: false"

      view |> element("#hello #toggle-status") |> render_click()
      assert render(hello_element) =~ "template_component: bar / status: true"

      view |> element("#hello #toggle-status") |> render_click()
      assert render(hello_element) =~ "template_component: bar / status: false"

      view |> element("#hello #set-status-true") |> render_click()
      assert render(hello_element) =~ "template_component: bar / status: true"

      view |> element("#hello #set-status-false") |> render_click()
      assert render(hello_element) =~ "template_component: bar / status: false"

      view |> element("#world #set-foo") |> render_click()
      assert render(world_element) =~ "template_component: foo / status: false"
    end

    test "live_component variation with template", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_live_component")
      hello_element = element(view, "#hello .lsb-sandbox")
      world_element = element(view, "#world .lsb-sandbox")

      assert render(hello_element) =~ "template_live_component: hello / status: false"
      assert render(world_element) =~ "template_live_component: world / status: false"

      view |> element("#hello #set-foo") |> render_click()
      assert render(hello_element) =~ "template_live_component: foo / status: false"

      view |> element("#hello #set-bar") |> render_click()
      assert render(hello_element) =~ "template_live_component: bar / status: false"

      view |> element("#hello #toggle-status") |> render_click()
      assert render(hello_element) =~ "template_live_component: bar / status: true"

      view |> element("#hello #toggle-status") |> render_click()
      assert render(hello_element) =~ "template_live_component: bar / status: false"

      view |> element("#world #set-foo") |> render_click()
      assert render(world_element) =~ "template_live_component: foo / status: false"
    end

    test "component variation_group with template", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component")

      variation_one = element(view, ~s|[id="group:one"] span|)
      variation_two = element(view, ~s|[id="group:two"] span|)

      assert render(variation_one) =~ "template_component: one / status: false"
      assert render(variation_two) =~ "template_component: two / status: false"

      view |> element(~s|[id="group:one"] #set-bar|) |> render_click()
      assert render(variation_one) =~ "template_component: bar / status: false"
      assert render(variation_two) =~ "template_component: two / status: false"

      view |> element(~s|[id="group:two"] #toggle-status|) |> render_click()
      assert render(variation_one) =~ "template_component: bar / status: false"
      assert render(variation_two) =~ "template_component: two / status: true"
    end

    test "can open playground from different variations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      element(view, "#hello a", "Open in playground") |> render_click()
      assert_patched(view, "/storybook/component?tab=playground&theme=default&variation_id=hello")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      view |> element("a", "Stories") |> render_click()

      element(view, "#world a", "Open in playground") |> render_click()
      assert_patched(view, "/storybook/component?tab=playground&theme=default&variation_id=world")
      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end
  end

  describe "page rendering" do
    test "renders a page story", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/a_page")
      assert html =~ "A Page"
      refute html =~ "story-tabs"
    end

    test "renders a page story with tabs", %{conn: conn} do
      {:ok, view, html} = live(conn, "/storybook/b_page")
      assert html =~ "B Page: tab_1"
      assert html =~ "story-tabs"

      html = view |> element("a", "Tab 2") |> render_click()
      assert_patched(view, "/storybook/b_page?tab=tab_2&theme=default")
      assert html =~ "B Page: tab_2"
    end
  end

  describe "search modal" do
    test "filters the search list based on user input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_page")

      assert has_element?(view, "#search-container a", "Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (a_folder)")

      view
      |> with_target("#search-container")
      |> render_change("search", %{"search" => %{"input" => "a_folder"}})

      refute has_element?(view, "#search-container a", "Component (root)")
      refute has_element?(view, "#search-container a", "Live Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (a_folder)")
    end

    test "returns everything on blank input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_page")

      assert has_element?(view, "#search-container a", "Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (a_folder)")

      view
      |> with_target("#search-container")
      |> render_change("search", %{"search" => %{"input" => ""}})

      assert has_element?(view, "#search-container a", "Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (root)")
      assert has_element?(view, "#search-container a", "Live Component (a_folder)")
    end

    test "navigates to a specified story", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_page")

      view
      |> with_target("#search-container")
      |> render_change("navigate", %{"path" => "/storybook/component"})

      assert_patch(view, "/storybook/component")
    end
  end
end
