defmodule PhxLiveStorybook.RouterTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias PhxLiveStorybook.TestRouter.Helpers, as: Routes

  test "generates helper for home" do
    assert Routes.live_storybook_path(build_conn(), :root) == "/storybook"
  end

  test "generates helper for entry" do
    assert Routes.live_storybook_path(build_conn(), :entry, ["components", "button"]) ==
             "/storybook/components/button"
  end

  test "generates helper for entry iframe" do
    assert Routes.live_storybook_path(build_conn(), :entry_iframe, ["components", "button"]) ==
             "/storybook/iframe/components/button"
  end

  test "raises when backend_module is missing" do
    assert_raise(RuntimeError, fn ->
      defmodule NoBackendModuleRouter do
        use Phoenix.Router
        import PhxLiveStorybook.Router

        live_storybook("/storybook", otp_app: :phx_live_storybook)
      end
    end)
  end

  test "raises when otp_app is missing" do
    assert_raise(RuntimeError, fn ->
      defmodule NoBackendModuleRouter do
        use Phoenix.Router
        import PhxLiveStorybook.Router

        live_storybook("/storybook", backend_module: PhxLiveStorybook.TestStorybook)
      end
    end)
  end
end
