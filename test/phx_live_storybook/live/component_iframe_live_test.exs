defmodule PhxLiveStorybook.ComponentIframeLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.ComponentIframeLiveEndpoint
  @moduletag :capture_log

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  describe "variation rendering" do
    test "it renders an story with a variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "theme" => "default"}
        )

      assert html =~ "component: hello"
    end

    test "it renders an story with a variation group", %{conn: conn} do
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

      view |> element("#set-foo") |> render_click()
      assert render(view) =~ "template_component: foo / status: false"

      view |> element("#set-bar") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#toggle-status") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view |> element("#toggle-status") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#set-status-true") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view |> element("#set-status-false") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"
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

  test "it raises with an unknow story", %{conn: conn} do
    assert_raise PhxLiveStorybook.StoryNotFound, fn ->
      live_with_params(conn, "/storybook/iframe/unknown", %{"variation_id" => "default"})
    end
  end

  defp live_with_params(conn, path, params) do
    live(conn, "#{path}?#{URI.encode_query(params)}")
  end
end
