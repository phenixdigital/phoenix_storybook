Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.StorybookTest do
  use ExUnit.Case
  import PhxLiveStorybook.MixHelper
  alias Mix.Tasks.Phx.Gen.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  @tag :capture_log
  test "mix phx.gen.storybook generates a working storybook", config do
    in_tmp_project(config.test, fn ->
      Storybook.run([])

      [{story, _}] = Code.compile_file("storybook/components/my_component.story.exs")
      assert story.storybook_type() == :component

      [{page, _}] = Code.compile_file("storybook/my_page.story.exs")
      assert page.storybook_type() == :page

      [{backend, _}] = Code.compile_file("lib/phx_live_storybook_web/storybook.ex")
      assert backend.storybook_path(story) == "/components/my_component"

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
