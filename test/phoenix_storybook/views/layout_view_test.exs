defmodule PhoenixStorybook.LayoutViewTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.Socket
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.{FolderEntry, StoryEntry}

  defmodule TestBackend do
    def config(key, default \\ nil) do
      Keyword.get(
        [
          font_awesome_plan: :free,
          sandbox_class: "root-sandbox",
          themes_strategies: [sandbox_class: "theme"],
          css_path: "storybook.css",
          js_path: "storybook.js"
        ],
        key,
        default
      )
    end

    def asset_hash(:css_path), do: "abc123"
    def asset_hash(:js_path), do: nil

    def find_entry_by_path("/folder"), do: %FolderEntry{name: "Folder"}
    def find_entry_by_path("/folder/story"), do: %StoryEntry{name: "Story"}
    def find_entry_by_path(_path), do: nil
  end

  defmodule DummyEndpoint do
    def script_name, do: ["storybook"]
  end

  defp build_test_conn do
    Phoenix.ConnTest.build_conn()
    |> Plug.Conn.put_private(:backend_module, TestBackend)
    |> Plug.Conn.put_private(:assets_path, "/assets")
    |> Plug.Conn.put_private(:live_socket_path, "/live")
    |> Plug.Conn.put_private(:csrf, "csrf-token")
    |> Plug.Conn.put_private(:csp_nonce_assign_key, %{script: :nonce_script})
    |> Plug.Conn.assign(:nonce_script, "nonce-conn")
    |> Map.put(:script_name, ["storybook"])
  end

  defp build_test_socket do
    assigns = %{
      backend_module: TestBackend,
      assets_path: "/assets",
      live_socket_path: "/live",
      csrf: "csrf-token",
      csp_nonces: %{script: "nonce-socket"}
    }

    %Socket{
      endpoint: DummyEndpoint,
      assigns: %Phoenix.LiveView.Socket.AssignsNotInSocket{__assigns__: assigns}
    }
  end

  test "render_breadcrumb uses backend entries" do
    socket = build_test_socket()

    html =
      LayoutView.render_breadcrumb(socket, "folder/story")
      |> Phoenix.LiveViewTest.rendered_to_string()

    assert html =~ ~r/Folder[\s\S]*Story/
  end

  test "live_socket_path uses socket assigns and endpoint script name" do
    socket = build_test_socket()
    path = LayoutView.live_socket_path(socket) |> IO.iodata_to_binary()
    assert path == "/storybook/live"
  end

  test "live_socket_path uses conn fields" do
    conn = build_test_conn()
    path = LayoutView.live_socket_path(conn) |> IO.iodata_to_binary()
    assert path == "/storybook/live"
  end

  test "storybook asset paths use configured values" do
    conn = build_test_conn()
    assert LayoutView.storybook_css_path(conn) == "storybook.css"
    assert LayoutView.storybook_js_path(conn) == "storybook.js"
    assert LayoutView.storybook_js_type(conn) == "text/javascript"
  end

  test "asset_path uses hashed JS assets and raw asset names" do
    conn = build_test_conn()
    js_hash = PhoenixStorybook.JSAssets.current_hash(:js)
    assert LayoutView.asset_path(conn, :js) == "/assets/js-#{js_hash}"
    assert LayoutView.asset_path(conn, "app.css") == "/assets/app.css"
  end

  test "storybook_css_hash and storybook_js_hash follow asset hash availability" do
    conn = build_test_conn()
    assert LayoutView.storybook_css_hash(conn) == "?hash=abc123"
    assert LayoutView.storybook_js_hash(conn) == ""
  end

  test "csrf and csp nonces use conn and socket data" do
    conn = build_test_conn()
    socket = build_test_socket()

    assert LayoutView.csrf?(conn) == "csrf-token"
    assert LayoutView.csrf?(socket) == "csrf-token"
    assert LayoutView.csp_nonce(conn, :script) == "nonce-conn"
    assert LayoutView.csp_nonce(socket, :script) == "nonce-socket"
    assert LayoutView.csp_nonce(%{script: "nonce-map"}, :script) == "nonce-map"
  end

  test "sandbox_class includes theme prefix when theme present" do
    conn = build_test_conn()

    no_theme = LayoutView.sandbox_class(conn, {:div, [class: "container"]}, %{theme: nil})
    with_theme = LayoutView.sandbox_class(conn, {:div, [class: "container"]}, %{theme: :default})

    refute Enum.member?(no_theme, "theme-default")
    assert Enum.member?(with_theme, "theme-default")
    assert Enum.member?(with_theme, "root-sandbox")
  end

  test "normalize_story_container sets defaults for div and iframe" do
    assert {:div, opts} = LayoutView.normalize_story_container(:div)
    assert Keyword.has_key?(opts, :class)

    assert {:div, opts} = LayoutView.normalize_story_container({:div, class: "custom"})
    assert opts[:class] == "custom"

    assert {:iframe, opts} = LayoutView.normalize_story_container(:iframe)
    assert Keyword.has_key?(opts, :style)

    assert {:iframe, opts} = LayoutView.normalize_story_container({:iframe, style: "custom"})
    assert opts[:style] == "custom"

    assert LayoutView.normalize_story_container({:section, class: "x"}) == {:section, class: "x"}
  end
end
