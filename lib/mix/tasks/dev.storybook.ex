defmodule Mix.Tasks.Dev.Storybook do
  @shortdoc "Make sure storybook is properly setup as a local dependency."
  @moduledoc """
  Make sure your storybook local dependency has all its assets packaged in priv.

  ```bash
  $> mix dev.storybook
  ```
  """

  use Mix.Task

  @doc false
  def run(_args) do
    Mix.shell().info("Setting up storybook for local development.")
    storybook_app = :phoenix_storybook
    current_app = Mix.Project.config()[:app]

    if storybook_app == current_app do
      setup_storybook(File.cwd!(), storybook_app)
    else
      case Mix.Project.deps_paths() |> Map.get(storybook_app) do
        nil -> Mix.raise("#{storybook_app} not found in your mix dependencies")
        dep_path -> setup_storybook(dep_path, storybook_app)
      end
    end

    :ok
  end

  defp setup_storybook(path, storybook_app) do
    Mix.shell().info("#{storybook_app} installed in #{path}")

    Mix.shell().info("* Running mix deps.get for #{storybook_app} dependency")
    cmd_unless_test("mix deps.get > /dev/null", cd: path)

    Mix.shell().info("* Running npm ci for #{storybook_app} dependency")
    cmd_unless_test("npm ci --prefix assets  > /dev/null", cd: path)

    Mix.shell().info("* Running mix assets.build for #{storybook_app} dependency")
    cmd_unless_test("mix assets.build", cd: path)
  end

  defp cmd_unless_test(cmd, opts) do
    unless Mix.env() == :test do
      Mix.shell().cmd(cmd, opts)
    end
  end
end
