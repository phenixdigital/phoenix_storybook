defmodule PhoenixStorybook.JSAssetsTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.JSAssets

  import Phoenix.ConnTest

  test "init" do
    assert JSAssets.init(:foo) == :foo
  end

  test "plug can serve JS bundle" do
    conn = build_conn() |> JSAssets.call(:js)
    assert conn.status == 200
    assert conn.resp_body =~ "js bundle"
  end

  test "plug can serve iframe JS bundle" do
    conn = build_conn() |> JSAssets.call(:iframejs)
    assert conn.status == 200
    assert conn.resp_body =~ "iframejs bundle"
  end

  test "renders 404 for unknown asset" do
    conn = build_conn() |> JSAssets.call(:no)
    assert conn.status == 404
  end

  test "current_hash" do
    assert JSAssets.current_hash(:js)
    assert JSAssets.current_hash(:iframejs)
  end
end
