defmodule PhoenixStorybook.PlaygroundLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixStorybook.PlaygroundLiveTestEndpoint
  @moduletag :capture_log

  use Phoenix.VerifiedRoutes, endpoint: @endpoint, router: PhoenixStorybook.TestRouter

  setup_all do
    start_supervised!(@endpoint)
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

      wait_for_preview_lv(view)
      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "renders playground code a simple component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      view |> element("a", "Code") |> render_click()
      assert view |> element("#playground pre") |> render() =~ "hello"
    end

    test "playground code is updated as form is changed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      view |> element("a", "Code") |> render_click()

      view
      |> form("#tree_storybook_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("#playground pre") |> render() =~ "world"

      view |> element("a", "Preview") |> render_click()
      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "we can switch to another variation from the playground", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      {:ok, view, _html} =
        view
        |> element("#variation-selection-form_variation_id")
        |> render_change(%{variation: %{variation_id: "world"}})
        |> follow_redirect(conn)

      assert view |> element("#playground-preview-live") |> render() =~ "component: world"
    end

    test "we can switch to another variation group from the playground", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/storybook/a_folder/live_component?tab=playground")
      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"

      {:ok, view, _html} =
        view
        |> element("#variation-selection-form_variation_id")
        |> render_change(%{variation: %{variation_id: "default"}})
        |> follow_redirect(conn)

      assert view |> element("#playground-preview-live") |> render() =~ "component: hello"
    end

    test "playground rendered HTML is available", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      view |> element("a", "HTML") |> render_click()

      view
      |> form("#tree_storybook_component-playground-form", %{playground: %{label: "world"}})
      |> render_change()

      assert view |> element("#playground pre") |> render() =~ "world"
    end

    test "playground rendered HTML is unavailable for live_components", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/live_component?tab=playground")
      refute has_element?(view, "a", "HTML")
    end
  end

  describe "attribute documentation" do
    test "renders simple attribute documentation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/let/let_component?tab=playground")

      assert view |> element("#tree_storybook_let_let_component-playground-form") |> render() =~
               "list of stories"
    end

    test "renders slot attribute documentation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/let/let_component?tab=playground")

      assert view |> element("#tree_storybook_let_let_component-playground-form") |> render() =~
               "slot documentation"
    end
  end

  describe "component in an iframe" do
    test "renders the playground preview iframe", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/live_component?tab=playground")
      assert html =~ ~S|<iframe id="tree_storybook_live_component-playground-preview"|
    end
  end

  describe "empty playground" do
    test "with no variations, it does not crash", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/component?tab=playground")
      assert html =~ "Component"
    end

    test "with no attributes, it prints a placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/storybook/b_folder/nested_component?tab=playground")
      assert html =~ ~r|In order to use playground, you must define your component attributes|
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

      wait_for_preview_lv(view)

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

      wait_for_preview_lv(view)

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

      wait_for_preview_lv(view)

      assert view |> element("#playground-preview-live") |> render() =~ "index_i: wrong"
    end

    test "component can be updated by selecting an option", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{option: "opt3"}
      })
      |> render_change()

      wait_for_preview_lv(view)

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

    test "a late evaluated attribute is properly displayed", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/b_folder/all_types_component?tab=playground&variation_id=with_eval"
        )

      assert view
             |> element("#tree_storybook_b_folder_all_types_component-playground-form_index_i")
             |> render() =~ ~s|value="10 + 15"|
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

  describe "theme switch in playground" do
    test "component preview is updated as a different theme is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      html = view |> element("#playground-preview-live") |> render()
      assert html =~ ~r|component:\s*hello\s*default|

      view |> element("a.psb-theme", "Colorful") |> render_click()
      wait_for_preview_lv(view)
      html = view |> element("#playground-preview-live") |> render()
      assert html =~ ~r|component:\s*hello\s*colorful|
    end

    test "playground form is updated as a different theme is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")
      form_theme_selector = "#tree_storybook_component-playground-form_theme"
      assert view |> element(form_theme_selector) |> render() =~ ~s|value=":default"|

      view |> element("a.psb-theme", "Colorful") |> render_click()

      wait_for_lv(view)
      assert view |> element(form_theme_selector) |> render() =~ ~s|value=":colorful"|
    end

    test "it doees not fail with no theme strategies", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/tree_storybook/component?tab=playground")
      html = view |> element("#playground-preview-live") |> render()
      assert html =~ ~r|component:\s*hello|
      refute html =~ ~r|default|
    end
  end

  describe "color mode switch" do
    test "component preview is updated as a different color mode is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/component?tab=playground")

      html = view |> element("#playground-preview-live") |> render()
      refute html =~ ~s|class="dark"|
      assert html =~ ~r|component:\s*hello\s*default|

      view
      |> element("#psb-colormode-dropdown")
      |> render_hook("psb-set-color-mode", %{"selected_mode" => "dark", "mode" => "dark"})

      wait_for_preview_lv(view)
      html = view |> element("#playground-preview-live .psb-sandbox") |> render()
      [component_class] = html |> Floki.parse_fragment!() |> Floki.attribute("class")
      assert component_class |> String.split(" ") |> Enum.member?("dark")
      assert html =~ ~r|component:\s*hello\s*default|
    end
  end

  describe "playground event logs" do
    test "it shows live_view type event log", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/event/event_component?tab=playground")

      events_tab_selector = "a[phx-click='lower-tab-navigation'][phx-value-tab='events']"
      refute view |> has_element?(events_tab_selector, "(1)")

      assert [playground_preview_view] = live_children(view)
      assert playground_preview_view |> element("button[phx-click='greet']") |> render_click()
      assert view |> has_element?(events_tab_selector, "(1)")

      assert view |> element(events_tab_selector) |> render_click()

      event_log = view |> element("#event_logs-0") |> render()

      assert event_log =~ "<code"
      assert event_log =~ ~r|<span class=".*">live_view</span>|
      assert event_log =~ ~r|<span class=".*">event:</span|
      assert event_log =~ ~r|<span class=".*">greet</span>|
    end

    test "it shows component type event log from a live component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/event/event_live_component?tab=playground")

      events_tab_selector = "a[phx-click='lower-tab-navigation'][phx-value-tab='events']"
      refute view |> has_element?(events_tab_selector, "(1)")

      assert [playground_preview_view] = live_children(view)

      assert playground_preview_view
             |> element("button[phx-click='greet_self']")
             |> render_click()

      wait_for_lv(view)
      assert view |> has_element?(events_tab_selector, "(1)")
      assert view |> element(events_tab_selector) |> render_click()

      event_log =
        view
        |> element("#event_logs-0")
        |> render()

      assert event_log =~ "<code"
      assert event_log =~ ~r|<span class=".*">component</span>|
      assert event_log =~ ~r|<span class=".*">event:</span|
      assert event_log =~ ~r|<span class=".*">greet_self</span>|
    end

    test "it shows live_view type event log from a live component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/event/event_live_component?tab=playground")

      events_tab_selector = "a[phx-click='lower-tab-navigation'][phx-value-tab='events']"
      refute view |> has_element?(events_tab_selector, "(1)")

      assert [playground_preview_view] = live_children(view)

      assert playground_preview_view
             |> element("button[phx-click='greet_parent']")
             |> render_click()

      assert view |> has_element?(events_tab_selector, "(1)")

      assert view |> element(events_tab_selector) |> render_click()

      event_log =
        view
        |> element("#event_logs-0")
        |> render()

      assert event_log =~ "<code"
      assert event_log =~ ~r|<span class=".*">live_view</span>|
      assert event_log =~ ~r|<span class=".*">event:</span|
      assert event_log =~ ~r|<span class=".*">greet_parent</span>|
    end
  end

  describe "template component in playground" do
    test "component rendering is updated as template buttons are clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component?tab=playground")
      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")
      assert render(playground_element) =~ "template_component: hello"

      playground_preview_view
      |> element("#set-foo-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: foo / status: false"

      playground_preview_view
      |> element("#set-bar-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view
      |> element("#toggle-status-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: true"

      playground_preview_view
      |> element("#toggle-status-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view
      |> element("#set-status-true-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: true"

      playground_preview_view
      |> element("#set-status-false-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: false"
    end

    test "playground form is in sync with variations assigns", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/templates/template_component?tab=playground")
      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~ "template_component: hello"

      playground_preview_view
      |> element("#set-foo-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: foo / status: false"

      form_selector = "#tree_storybook_template_component-playground-form"
      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert get_element_attribute(view, form_label_selector, "value") == "foo"

      view |> form(form_selector, %{playground: %{label: "bar"}}) |> render_change()
      wait_for_preview_lv(view)
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view
      |> element("#toggle-status-template-component-single-hello")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: true"

      wait_for_lv(view)
      assert get_element_attribute(view, form_toggle_selector, "value") == "true"
      view |> form(form_selector, %{playground: %{status: true}}) |> render_change()
      wait_for_preview_lv(view)
      assert render(playground_element) =~ "template_component: bar / status: true"
    end

    test "playground form is in sync with a group of variations", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, "/storybook/templates/template_component?tab=playground&variation_id=group")

      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~ "template_component: one"
      assert render(playground_element) =~ "template_component: two"

      playground_preview_view
      |> element("#set-foo-template-component-group-one")
      |> render_click()

      assert render(playground_element) =~ "template_component: foo / status: false"
      assert render(playground_element) =~ "template_component: two / status: false"

      form_selector = "#tree_storybook_template_component-playground-form"
      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert get_element_attribute(view, form_label_selector, "value") == "[Multiple values]"

      playground_preview_view
      |> element("#set-foo-template-component-group-two")
      |> render_click()

      assert render(playground_element) =~ "template_component: foo / status: false"
      refute render(playground_element) =~ "template_component: bar / status: false"

      view |> form(form_selector, %{playground: %{label: "bar"}}) |> render_change()
      assert render(playground_element) =~ "template_component: bar / status: false"

      playground_preview_view
      |> element("#toggle-status-template-component-group-one")
      |> render_click()

      assert render(playground_element) =~ "template_component: bar / status: true"
      assert render(playground_element) =~ "template_component: bar / status: false"

      wait_for_lv(view)
      assert get_element_attribute(view, form_toggle_selector, "value") == "[Multiple values]"

      playground_preview_view
      |> element("#toggle-status-template-component-group-two")
      |> render_click()

      wait_for_lv(view)
      view |> form(form_selector, %{playground: %{status: "true"}}) |> render_change()

      wait_for_preview_lv(view)
      assert render(playground_element) =~ "template_component: bar / status: true"
      refute render(playground_element) =~ "template_component: bar / status: false"
    end

    test "playground with template examples", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&variation_id=template_attributes"
        )

      assert [playground_preview_view] = live_children(view)
      playground_element = element(playground_preview_view, "#playground-preview-live")

      assert render(playground_element) =~
               "<span>template_component: from_template / status: true</span>"

      form_label_selector = "#tree_storybook_template_component-playground-form_label"
      form_toggle_selector = "#tree_storybook_template_component-playground-form_status"

      assert view
             |> element(form_label_selector)
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.attribute("disabled") ==
               ["disabled"]

      assert view
             |> element(form_toggle_selector)
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.attribute("disabled") ==
               ["disabled"]
    end

    test "playground with a variation_group, and an empty template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&variation_id=no_placeholder_group"
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

    test "component code is visible for a variation_group with a template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&variation_id=group_template"
        )

      view |> element("a", "Code") |> render_click()
      assert view |> element("pre") |> render() =~ "one"
    end

    test "component code is visible for a variation_group with a single template", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/storybook/templates/template_component?tab=playground&variation_id=group_template_single"
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

  defp wait_for_lv(view) do
    :sys.get_state(view.pid)
  end

  defp wait_for_preview_lv(view) do
    [playground_preview_view] = live_children(view)
    :sys.get_state(playground_preview_view.pid)
  end
end

defmodule PhoenixStorybook.PlaygroundLiveNonAsyncTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixStorybook.PlaygroundLiveTestEndpoint
  @moduletag :capture_log

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  describe "component preview crash handling" do
    test "an error message is displayed when component crashes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/storybook/b_folder/all_types_component?tab=playground")
      wait_for_lv(view)
      Process.flag(:trap_exit, true)

      view
      |> form("#tree_storybook_b_folder_all_types_component-playground-form", %{
        playground: %{label: "raise"}
      })
      |> render_change()

      wait_for_lv(view)
      assert_receive {:EXIT, _, {%RuntimeError{message: "booooom!"}, _}}, 200
    end
  end

  defp wait_for_lv(view) do
    :sys.get_state(view.pid)
  end
end
