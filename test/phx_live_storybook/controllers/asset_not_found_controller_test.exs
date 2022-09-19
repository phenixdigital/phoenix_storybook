defmodule PhxLiveStorybook.AssetNotFoundControllerTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest, only: [build_conn: 0, get: 2]
  alias PhxLiveStorybook.TestRouter.Helpers, as: Routes

  @endpoint PhxLiveStorybook.StoryLiveTestEndpoint
  @moduletag :capture_log

  setup do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  test "it raises, whatever the path", %{conn: conn} do
    assert_raise PhxLiveStorybook.AssetNotFound, fn ->
      get(conn, Routes.storybook_asset_path(conn, :asset, ["foo"]))
    end
  end
end
