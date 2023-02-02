defmodule Mix.Tasks.Dev.StorybookTest do
  use ExUnit.Case
  alias Mix.Tasks.Dev.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  test "mix dev.storybook" do
    Storybook.run([])
    assert_receive {:mix_shell, :info, ["* Running mix deps.get for phoenix_storybook dependency"]}
    assert_receive {:mix_shell, :info, ["* Running npm ci for phoenix_storybook dependency"]}
    assert_receive {:mix_shell, :info, ["* Running mix assets.build for phoenix_storybook dependency"]}
  end

end
