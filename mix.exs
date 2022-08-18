defmodule PhxLiveStorybook.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :phx_live_storybook,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      config_path: "./config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: "A pluggable storybook for your LiveView components.",
      package: package(),
      name: "phx_live_storybook",
      source_url: "https://github.com/phenixdigital/phx_live_storybook",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.lcov": :test,
        coverage: :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PhxLiveStorybook.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.17.11"},
      {:makeup_eex, "~> 0.1.0"},
      {:jason, "~> 1.3", optional: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:floki, "~> 0.33.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "PhxLiveStorybook",
      source_ref: "v#{@version}",
      source_url: "https://github.com/phenixdigital/phx_live_storybook",
      extra_section: "GUIDES",
      extras: extras(),
      nest_modules_by_prefix: [PhxLiveStorybook]
    ]
  end

  defp extras do
    [
      "guides/sandboxing.md"
    ]
  end

  defp package do
    [
      maintainers: ["Christian Blavier"],
      files: ~w(mix.exs priv lib guides README.md LICENSE.md CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/phenixdigital/phx_live_storybook"}
    ]
  end

  defp aliases do
    [
      "assets.watch": "cmd npm run watch --prefix assets",
      "assets.build": [
        "cmd npm run build --prefix assets",
        "phx.digest",
        "phx.digest.clean"
      ],
      coverage: "coveralls.lcov"
    ]
  end
end
