defmodule PhxLiveStorybook.ComponentIframeLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhxLiveStorybook.EntryLiveTestEndpoint
  @moduletag :capture_log

  setup do
    start_supervised!(PhxLiveStorybook.EntryLiveTestEndpoint)
    {:ok, conn: build_conn()}
  end

  describe "story rendering" do
    test "it renders an entry with a story", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"story_id" => "hello", "theme" => "default"}
        )

      assert html =~ "component: hello"
    end

    test "it renders an entry with a story group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"story_id" => "group", "theme" => "colorful"}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "story with a template", %{conn: conn} do
      {:ok, view, html} =
        live_with_params(conn, "/storybook/iframe/templates/template_iframe_component", %{
          "story_id" => "hello",
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
    test "it renders a playground with a story", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"story_id" => "hello", "playground" => true}
        )

      assert html =~ "component: hello"
    end

    test "it renders a playground with a story group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"story_id" => "group", "playground" => true}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end
  end

  test "it raises with an unknow entry", %{conn: conn} do
    assert_raise PhxLiveStorybook.EntryNotFound, fn ->
      live_with_params(conn, "/storybook/iframe/unknown", %{"story_id" => "default"})
    end
  end

  defp live_with_params(conn, path, params) do
    live(conn, "#{path}?#{URI.encode_query(params)}")
  end
end
