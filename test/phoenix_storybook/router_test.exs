defmodule PhoenixStorybook.RouterTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias PhoenixStorybook.TestRouter.Helpers, as: Routes

  describe "live_storybook_path/2" do
    test "generates helper for home" do
      assert Routes.live_storybook_path(build_conn(), :root) == "/storybook"
    end

    test "generates helper for story" do
      assert Routes.live_storybook_path(build_conn(), :story, ["components", "button"]) ==
               "/storybook/components/button"
    end

    test "generates helper for story iframe" do
      assert Routes.live_storybook_path(build_conn(), :story_iframe, ["components", "button"]) ==
               "/storybook/iframe/components/button"
    end

    test "generates helper for home when :as option is passed" do
      assert Routes.admin_live_storybook_path(build_conn(), :root) == "/admin/storybook"
    end

    test "generates helper for story when :as option is passed" do
      assert Routes.admin_live_storybook_path(build_conn(), :story, ["components", "button"]) ==
               "/admin/storybook/components/button"
    end

    test "generates helper for story iframe when :as option is passed" do
      assert Routes.admin_live_storybook_path(build_conn(), :story_iframe, [
               "components",
               "button"
             ]) == "/admin/storybook/iframe/components/button"
    end

    test "raises when backend_module is missing" do
      assert_raise(RuntimeError, fn ->
        defmodule NoBackendModuleRouter do
          use Phoenix.Router
          import PhoenixStorybook.Router

          live_storybook("/storybook", [])
        end
      end)
    end
  end

  describe "storybook_assets/1" do
    test "generates helper for any asset" do
      assert Routes.storybook_asset_path(build_conn(), :asset, ["js", "phoenix_storybook.js"]) ==
               "/storybook/assets/js/phoenix_storybook.js"
    end
  end
end
