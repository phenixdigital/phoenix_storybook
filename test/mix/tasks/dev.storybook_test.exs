Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Dev.StorybookTest do
  use ExUnit.Case
  alias Mix.Tasks.Dev.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  test "mix dev.storybook" do
    assert_raise Mix.Error, "phx_live_storybook not found in your mix dependencies", fn ->
      Storybook.run([])
    end
  end

end
