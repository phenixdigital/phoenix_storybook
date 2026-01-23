defmodule PhoenixStorybook.ComponentIframeLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixStorybook.ComponentIframeLiveEndpoint
  @moduletag :capture_log

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  describe "variation rendering" do
    test "it renders a story with a variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "theme" => "default"}
        )

      assert html =~ "component: hello"
    end

    test "it renders a story with a variation group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"variation_id" => "group", "theme" => "colorful"}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "variation with a template", %{conn: conn} do
      {:ok, view, html} =
        live_with_params(conn, "/storybook/iframe/templates/template_iframe_component", %{
          "variation_id" => "hello",
          "theme" => "default"
        })

      assert html =~ "template_component: hello / status: false"

      view |> element("#set-foo-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: foo / status: false"

      view |> element("#set-bar-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#toggle-status-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view |> element("#toggle-status-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#set-status-true-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view
      |> element("#set-status-false-template-iframe-component-single-hello")
      |> render_click()

      assert render(view) =~ "template_component: bar / status: false"
    end

    test "it renders an story with a color theme", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "theme" => "default", "color_mode" => "dark"}
        )

      assert html =~ ~r|class="[^"]*dark[^"]*"|
      assert html =~ "component: hello"
    end
  end

  describe "playground" do
    test "it renders a playground with a variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true}
        )

      assert html =~ "component: hello"
    end

    test "it renders a playground with a color_mode", %{conn: conn} do
      {:ok, view, _html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true, "color_mode" => "dark"}
        )

      html = view |> element(".psb-sandbox") |> render()
      [class] = html |> LazyHTML.from_fragment() |> LazyHTML.attribute("class")
      assert class |> String.split(" ") |> Enum.member?("dark")
      assert html =~ "component: hello"
    end

    test "it renders a playground with a light color_mode", %{conn: conn} do
      {:ok, view, _html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true, "color_mode" => "light"}
        )

      html = view |> element(".psb-sandbox") |> render()
      [class] = html |> LazyHTML.from_fragment() |> LazyHTML.attribute("class")
      assert class |> String.split(" ") |> Enum.member?("light")
      assert html =~ "component: hello"
    end

    test "it renders a playground with a variation group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"variation_id" => "group", "playground" => true}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end
  end

  test "it raises with an unknown story", %{conn: conn} do
    assert_raise RuntimeError, fn ->
      live_with_params(conn, "/storybook/iframe/unknown", %{"variation_id" => "default"})
    end
  end

  defp live_with_params(conn, path, params) do
    live(conn, "#{path}?#{URI.encode_query(params)}")
  end
end
