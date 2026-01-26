defmodule PhoenixStorybook.JSAssetsTest do
  use ExUnit.Case, async: false

  alias PhoenixStorybook.JSAssets
  alias PhoenixStorybook.JSAssets.JSFile

  import Phoenix.ConnTest
  import Plug.Conn, only: [get_resp_header: 2]

  test "init" do
    assert JSAssets.init(:foo) == :foo
  end

  test "plug can serve JS bundle" do
    conn = build_conn() |> JSAssets.call(:js)
    assert conn.status == 200
    assert conn.resp_body =~ "LiveSocket"
  end

  test "plug can serve iframe JS bundle" do
    conn = build_conn() |> JSAssets.call(:iframejs)
    assert conn.status == 200
    assert conn.resp_body =~ "LiveSocket"
  end

  test "renders 404 for unknown asset" do
    conn = build_conn() |> JSAssets.call(:no)
    assert conn.status == 404
  end

  test "current_hash" do
    assert JSAssets.current_hash(:js)
    assert JSAssets.current_hash(:iframejs)
  end

  test "JSFile.read returns empty string for missing file" do
    assert JSFile.read("/tmp/phoenix_storybook_missing.js") == ""
  end

  test "JSFile.read returns file contents when file exists" do
    path =
      Path.expand("../../fixtures/storybook_content/flat_list/a_component.story.exs", __DIR__)

    assert JSFile.read(path) =~ "defmodule"
  end

  test "gzip assets add header and compress content" do
    on_exit(fn -> recompile_js_assets!(false) end)
    recompile_js_assets!(true)

    conn = build_conn() |> JSAssets.call(:js)
    assert get_resp_header(conn, "content-encoding") == ["gzip"]
    assert :zlib.gunzip(conn.resp_body) =~ "LiveSocket"
  end

  defp recompile_js_assets!(gzip?) do
    path = Path.expand("../../../lib/phoenix_storybook/controllers/js_assets.ex", __DIR__)
    Application.put_env(:phoenix_storybook, :gzip_assets, gzip?)

    :code.purge(JSAssets)
    :code.delete(JSAssets)

    previous_opts = Code.compiler_options()
    Code.compiler_options(ignore_module_conflict: true)

    try do
      Code.compile_file(path)
    after
      Code.compiler_options(previous_opts)
    end
  end
end
