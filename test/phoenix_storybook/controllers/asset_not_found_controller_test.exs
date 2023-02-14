defmodule PhoenixStorybook.AssetNotFoundControllerTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest, only: [build_conn: 0, get: 2]
  alias PhoenixStorybook.TestRouter.Helpers, as: Routes
  @endpoint PhoenixStorybook.AssetNotFoundControllerEndpoint
  @moduletag :capture_log

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  test "it raises, whatever the path", %{conn: conn} do
    assert_raise PhoenixStorybook.AssetNotFound, fn ->
      get(conn, Routes.storybook_asset_path(conn, :asset, ["foo"]))
    end
  end
end
