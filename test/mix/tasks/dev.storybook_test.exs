Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Dev.StorybookShell do
  @behaviour Mix.Shell

  def info(message) do
    print_app()
    send(self(), {:mix_shell, :info, [format(message)]})
    :ok
  end

  def error(message) do
    print_app()
    send(self(), {:mix_shell, :error, [format(message)]})
    :ok
  end

  def prompt(_message) do
    print_app()
    ""
  end

  def yes?(_message, _options \\ []) do
    print_app()
    true
  end

  def print_app do
    _ = Mix.Shell.printable_app_name()
    :ok
  end

  def cmd(command), do: cmd(command, [])

  def cmd(command, opts) do
    print_app()
    send(self(), {:mix_shell, :cmd, [command, opts]})
    0
  end

  defp format(message) do
    message |> IO.ANSI.format(false) |> IO.iodata_to_binary()
  end
end

defmodule Mix.Tasks.Dev.StorybookTest do
  use ExUnit.Case
  import PhoenixStorybook.MixHelper
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

  test "mix dev.storybook runs commands outside test env" do
    previous_env = Mix.env()
    previous_shell = Mix.shell()
    Mix.State.put(:env, :dev)
    Mix.shell(Mix.Tasks.Dev.StorybookShell)

    on_exit(fn ->
      Mix.State.put(:env, previous_env)
      Mix.shell(previous_shell)
    end)

    Storybook.run([])

    assert_receive {:mix_shell, :cmd, ["mix deps.get > /dev/null", _opts]}
    assert_receive {:mix_shell, :cmd, ["npm ci --prefix assets  > /dev/null", _opts]}
    assert_receive {:mix_shell, :cmd, ["mix assets.build", _opts]}
  end

  test "mix dev.storybook uses dependency path when current app differs", config do
    repo_root = Path.expand("../../../..", __DIR__)

    in_tmp_project(config.test, fn ->
      File.write!("mix.exs", """
      defmodule DummyDeps.MixProject do
        use Mix.Project

        def project do
          [
            app: :dummy_deps,
            version: "0.1.0",
            elixir: "~> 1.15",
            deps: [{:phoenix_storybook, path: "#{repo_root}"}]
          ]
        end
      end
      """)

      Mix.Project.in_project(:dummy_deps, ".", fn _ ->
        project = Mix.Project.get()
        env_target = {Mix.env(), Mix.target()}
        dep = %Mix.Dep{app: :phoenix_storybook, opts: [dest: repo_root], top_level: true}
        Mix.State.write_cache({:cached_deps, project}, {env_target, [dep]})

        Storybook.run([])
      end)

      assert_receive {:mix_shell, :info, ["phoenix_storybook installed in " <> _path]}
    end)
  end

  test "mix dev.storybook raises when dependency missing", config do
    in_tmp_project(config.test, fn ->
      File.write!("mix.exs", """
      defmodule Dummy.MixProject do
        use Mix.Project

        def project do
          [
            app: :dummy,
            version: "0.1.0",
            elixir: "~> 1.15",
            deps: []
          ]
        end
      end
      """)

      original_project = Mix.Project.get()

      try do
        assert_raise Mix.Error, "phoenix_storybook not found in your mix dependencies", fn ->
          Mix.Project.in_project(:dummy, ".", fn _ -> Storybook.run([]) end)
        end
      after
        restore_project(original_project)
      end
    end)
  end

  defp restore_project(original_project) do
    current_project = Mix.Project.get()

    cond do
      current_project == original_project -> :ok
      current_project == nil -> :ok
      true -> Mix.Project.pop() && restore_project(original_project)
    end
  end
end
