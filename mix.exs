defmodule PhxLiveStorybook.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_live_storybook,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.17.11"},
      {:makeup_eex, "~> 0.1.0"}
    ]
  end

  defp aliases do
    [
      "assets.watch": "cmd npm run watch --prefix assets"
    ]
  end
end
