defmodule PhoenixStorybook.StoryLiveTest do
  use ExUnit.Case, async: true

  @endpoint PhoenixStorybook.StoryLiveTestEndpoint
  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import ExUnit.CaptureLog

  use Phoenix.VerifiedRoutes, endpoint: @endpoint, router: PhoenixStorybook.TestRouter

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

    test "error message on unknown story", %{conn: conn} do
      log = capture_log(fn -> get(conn, "/storybook/wrong") end)
      assert log =~ ~s|Could not compile "wrong.story.exs"|
    end

    test "navigate in sidebar", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      assert view |> element("#sidebar a", "Live Component (root)") |> render_click() =~
               "LiveComponent first doc paragraph."

      # A folder is open
      refute has_element?(view, "#sidebar a", "Component (a_folder)")

      # Opening A folder
      element(view, "#sidebar div", "A Folder") |> render_click()
      assert has_element?(view, "#sidebar a", "Component (a_folder)")

      # B folder is alredy open (by its index.exs file)
      assert has_element?(view, "#sidebar a", "AllTypesComponent (b_folder)")

      # reaching items inside
      assert view |> element("#sidebar a", "AllTypesComponent (b_folder)") |> render_click() =~
               "All types component description"

      # closing "B folder"
      element(view, "#sidebar div", "Config Name") |> render_click()
      refute has_element?(view, "#sidebar a", "AllTypesComponent (b_folder)")
    end

    test "navigate to unknown tab", %{conn: conn} do
      assert_raise PhoenixStorybook.StoryTabNotFound, fn ->
        get(conn, "/storybook/component", tab: "unknown")
      end
    end
  end

  describe "variation rendering" do
    test "renders component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/component")
      assert html =~ "Component"
      assert html =~ "Component first doc paragraph."
      assert html =~ "Hello variation"
      assert html =~ "World variation"
    end

    test "renders live component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/live_component")
      assert html =~ "Live Component"
      assert html =~ "LiveComponent first doc paragraph."
      assert html =~ "Hello variation"
      assert html =~ "World"
    end

    test "renders nested component story from path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/a_folder/component")
      assert html =~ "Component"
      assert html =~ "Component first doc paragraph."
    end

    test "no-ops events from an event component", %{conn: conn} do
      {:ok, view, html} = live(conn, "/storybook/event/event_component")
      assert html =~ "Hello variation"
      view |> element("#event-component") |> render_click()
      # This will raise if there's no default handle_event clause
      assert true
    end

    test "renders component story and navigate to source tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      html = view |> element("a", "Source") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :source, theme: :default, variation_id: :hello]}"
      )

      assert html =~ "defmodule"
    end

    test "renders component, change theme and navigate", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      view |> element("a.psb-theme", "Colorful") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :variations, theme: :colorful, variation_id: :hello]}"
      )

      view |> element("a", "Source") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :source, theme: :colorful, variation_id: :hello]}"
      )

      html = view |> element("a", "Playground") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :playground, theme: :colorful, variation_id: :hello]}"
      )

      assert html =~ "component: hello colorful"

      Phoenix.PubSub.subscribe(PhoenixStorybook.PubSub, "playground-#{inspect(view.pid)}")
      view |> element("a.psb-theme", "Default") |> render_click()
      assert_receive {:set_theme, :default}

      assert view |> element("#tree_storybook_component-playground-preview") |> render() =~
               "component: hello default"
    end

    test "renders component story and navigate to source tab with select", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      html =
        view
        |> element(".story-nav-form select")
        |> render_change(%{navigation: %{tab: "source"}})

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :source, theme: :default, variation_id: :hello]}"
      )

      assert html =~ "defmodule"
    end

    test "component variation with template", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component")
      hello_element = element(view, "#hello .psb-sandbox")
      world_element = element(view, "#world .psb-sandbox")

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
      hello_element = element(view, "#hello .psb-sandbox")
      world_element = element(view, "#world .psb-sandbox")

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

      variation_one = element(view, ~s|[id="template-component-group-one"] span|)
      variation_two = element(view, ~s|[id="template-component-group-two"] span|)

      assert render(variation_one) =~ "template_component: one / status: false"
      assert render(variation_two) =~ "template_component: two / status: false"

      view |> element(~s|[id="template-component-group-one"] #set-bar|) |> render_click()
      assert render(variation_one) =~ "template_component: bar / status: false"
      assert render(variation_two) =~ "template_component: two / status: false"

      view |> element(~s|[id="template-component-group-two"] #toggle-status|) |> render_click()
      assert render(variation_one) =~ "template_component: bar / status: false"
      assert render(variation_two) =~ "template_component: two / status: true"
    end

    test "can open playground from different variations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      element(view, "#hello a", "Open in playground") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :playground, theme: :default, variation_id: :hello]}"
      )

      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      view |> element("a", "Stories") |> render_click()

      element(view, "#world a", "Open in playground") |> render_click()

      assert_patched(
        view,
        ~p"/storybook/component?#{[tab: :playground, theme: :default, variation_id: :world]}"
      )

      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "sandbox container is default flex div", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")
      html = view |> element("#hello .psb-sandbox") |> render() |> Floki.parse_fragment!()

      assert [
               {"div",
                [
                  {"class",
                   "theme-prefix-default psb-sandbox psb-flex psb-flex-col psb-items-center psb-gap-y-[5px] psb-p-[5px]"}
                ], _}
             ] = html
    end

    test "sandbox container is customized div", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/a_folder/component")
      html = view |> element("#group .psb-sandbox") |> render() |> Floki.parse_fragment!()

      assert [
               {"div",
                [
                  {"class", "theme-prefix-default psb-sandbox block"},
                  {"data-foo", "bar"}
                ], _}
               | _
             ] = html
    end

    test "function component container is a srcdoc iframe", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/containers/components/iframe")

      [{"iframe", attrs, _}] =
        view
        |> element("#iframe-tree_storybook_containers_components_iframe-variation-hello")
        |> render()
        |> Floki.parse_fragment!(attributes_as_maps: true)

      refute is_nil(attrs["srcdoc"])
    end

    test "function component container is a srcdoc iframe with custom opts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/containers/components/iframe_with_opts")

      [{"iframe", attrs, _}] =
        view
        |> element(
          "#iframe-tree_storybook_containers_components_iframe_with_opts-variation-hello"
        )
        |> render()
        |> Floki.parse_fragment!(attributes_as_maps: true)

      refute is_nil(attrs["srcdoc"])
      assert attrs["data-foo"] == "bar"
    end

    test "live component container is a regular iframe", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/containers/live_components/iframe")

      [{"iframe", attrs, _}] =
        view
        |> element("#iframe-tree_storybook_containers_live_components_iframe-variation-hello")
        |> render()
        |> Floki.parse_fragment!(attributes_as_maps: true)

      assert attrs["src"] ==
               "/storybook/iframe/containers/live_components/iframe?theme=default&variation_id=hello"

      assert is_nil(attrs["srcdoc"])
    end

    test "renders with different layouts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")

      component_html = view |> element("#hello-component") |> render() |> Floki.parse_fragment!()
      [{"id", _id}, {"class", class}] = component_html |> Enum.at(0) |> elem(1)
      assert class =~ "lg:psb-col-span-2"

      code_html = view |> element("#hello-code") |> render() |> Floki.parse_fragment!()
      [{"id", _id}, {"class", class}] = code_html |> Enum.at(0) |> elem(1)
      assert class =~ "lg:psb-col-span-3"

      {:ok, view, _html} = live(conn, "/storybook/live_component")

      component_html = view |> element("#hello-component") |> render() |> Floki.parse_fragment!()
      [{"id", _id}, {"class", class}] = component_html |> Enum.at(0) |> elem(1)
      refute class =~ "lg:psb-col-span-2"

      code_html = view |> element("#hello-code") |> render() |> Floki.parse_fragment!()
      [{"id", _id}, {"class", class}] = code_html |> Enum.at(0) |> elem(1)
      refute class =~ "lg:psb-col-span-3"
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
      assert_patched(view, ~p"/storybook/b_page?#{[tab: :tab_2, theme: :default]}")
      assert html =~ "B Page: tab_2"
    end
  end

  describe "example rendering" do
    test "renders an example story", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/examples/example")
      assert html =~ "Example story"
      assert html =~ "Example template"
    end

    test "renders an example story main source tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/examples/example")
      html = view |> element("a", "example.story.ex") |> render_click()
      assert html =~ ~r/defmodule.*TreeStorybook\.Examples\.Example/
      refute html =~ ~r/extra_sources/
      refute html =~ ~r/doc/
      refute html =~ ~r/PhoenixStorybook/
    end

    test "renders an example story extra source tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/examples/example")
      html = view |> element("a", "example.html.heex") |> render_click()
      assert html =~ ~r/Example.*template/
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

      assert_patch(view, "/storybook/component", 200)
    end
  end

  describe "theme strategies" do
    test "theme is set on the sandbox with the default strategy", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")
      html = view |> element("#hello .psb-sandbox") |> render() |> Floki.parse_fragment!()

      assert [{"div", [{"class", classes}], _}] = html
      assert classes =~ "theme-prefix-default"
    end
  end

  describe "color mode change" do
    test "send psb-set-color-mode will change color mode in picker", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component")
      refute view |> has_element?("#psb-colormode-dropdown[data-selected-mode=dark]")

      component_html = view |> element("#hello-component") |> render()
      [component_class] = component_html |> Floki.parse_fragment!() |> Floki.attribute("class")
      refute component_class |> String.split(" ") |> Enum.member?("dark")

      view
      |> element("#psb-colormode-dropdown")
      |> render_hook("psb-set-color-mode", %{"selected_mode" => "dark", "mode" => "dark"})

      assert view |> has_element?("#psb-colormode-dropdown[data-selected-mode=dark]")

      component_html = view |> element("#hello-component") |> render()
      [component_class] = component_html |> Floki.parse_fragment!() |> Floki.attribute("class")
      assert component_class |> String.split(" ") |> Enum.member?("dark")
    end
  end
end
