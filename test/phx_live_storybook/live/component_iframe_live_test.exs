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

  test "it renders an entry with a story", %{conn: conn} do
    {:ok, _view, html} =
      live_with_params(
        conn,
        "/storybook/iframe/a_component",
        %{"story_id" => "hello", "parent_pid" => inspect(self())}
      )

    assert html =~ "a component: hello"
  end

  test "it renders an entry with a story group", %{conn: conn} do
    {:ok, _view, html} =
      live_with_params(
        conn,
        "/storybook/iframe/a_folder/aa_component",
        %{"story_id" => "group"}
      )

    assert html =~ "a component: hello"
    assert html =~ "a component: world"
  end

  test "it renders a playground with a story", %{conn: conn} do
    {:ok, _view, html} =
      live_with_params(
        conn,
        "/storybook/iframe/a_component",
        %{"story_id" => "hello", "playground" => true}
      )

    assert html =~ "a component: hello"
  end

  test "it renders a playground with a story group", %{conn: conn} do
    {:ok, _view, html} =
      live_with_params(
        conn,
        "/storybook/iframe/a_folder/aa_component",
        %{"story_id" => "[group, hello]", "playground" => true}
      )

    assert html =~ "a component: hello"
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
