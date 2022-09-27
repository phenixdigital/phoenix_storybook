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
    Mix.shell().info("Setup storybook for local development.")
    app = :phx_live_storybook

    case Mix.Project.deps_paths() |> Map.get(app) do
      nil ->
        Mix.raise("#{app} not found in your mix dependencies")

      dep_path ->
        Mix.shell().info("#{app} installed in #{dep_path}")

        Mix.shell().info("- Running mix deps.get for #{app} dependency")
        Mix.shell().cmd("mix deps.get > /dev/null", cd: dep_path)

        Mix.shell().info("- Running npm ci for #{app} dependency")
        Mix.shell().cmd("npm ci --prefix assets  > /dev/null", cd: dep_path)

        Mix.shell().info("- Running mix assets.build for #{app} dependency")
        Mix.shell().cmd("mix assets.build  > /dev/null", cd: dep_path)
    end

    :ok
  end
end
