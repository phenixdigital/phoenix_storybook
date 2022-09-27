Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Dev.StorybookTest do
  use ExUnit.Case
  alias Mix.Tasks.Dev.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  test "mix dev.storybook" do
    Storybook.run([])
    assert_receive {:mix_shell, :info, ["* Running mix deps.get for phx_live_storybook dependency"]}
    assert_receive {:mix_shell, :info, ["* Running npm ci for phx_live_storybook dependency"]}
    assert_receive {:mix_shell, :info, ["* Running mix assets.build for phx_live_storybook dependency"]}
  end

end
