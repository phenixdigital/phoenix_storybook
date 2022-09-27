Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.ReleaseTest do
  use ExUnit.Case
  import PhxLiveStorybook.MixHelper
  alias Mix.Tasks.Phx.Gen.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  test "generates storybook files", config do
    in_tmp_project(config.test, fn ->
      Storybook.run([])

      assert_file("lib/phx_live_storybook_web/storybook.ex", fn file ->
        assert file =~ ~S|defmodule PhxLiveStorybookWeb.Storybook do|
      end)

      assert_file("storybook/components/my_component.story.exs", fn file ->
        assert file =~ ~S|defmodule Storybook.Components.MyComponent do|
      end)

      assert_file("storybook/my_page.story.exs", fn file ->
        assert file =~ ~S|defmodule Storybook.MyPage do|
      end)

      assert_file("assets/js/storybook.js")
      assert_file("assets/css/storybook.css")

      assert_receive {:mix_shell, :info, ["* creating lib/phx_live_storybook_web/storybook.ex"]}
      assert_receive {:mix_shell, :info, ["* creating storybook/components/my_component.story.exs"]}
      assert_receive {:mix_shell, :info, ["* creating storybook/my_page.story.exs"]}
      assert_receive {:mix_shell, :info, ["* creating assets/js/storybook.js"]}
      assert_receive {:mix_shell, :info, ["* creating assets/css/storybook.css"]}
    end)
  end
end
