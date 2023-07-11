defmodule PhoenixStorybook.MixProject do
  use Mix.Project

  @version "0.5.4"

  def project do
    [
      app: :phoenix_storybook,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      config_path: "./config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "phoenix_storybook",
      description: "A pluggable storybook for your Phoenix components.",
      source_url: "https://github.com/phenixdigital/phoenix_storybook",
      aliases: aliases(),
      deps: deps(),
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.lcov": :test,
        coverage: :test
      ],
      dialyzer: [
        plt_add_apps: [:mix, :jason, :earmark],
        plt_local_path: ".plts",
        plt_core_path: ".plts",
        plt_file: {:no_warn, ".plts/storybook.plt"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PhoenixStorybook.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "> 0.18.7"},
      {:phoenix_view, "~> 2.0"},
      {:makeup_eex, "~> 0.1.0"},
      {:heroicons, "~> 0.5", optional: true},
      {:jason, "~> 1.3", optional: true},
      {:earmark, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:floki, "~> 0.34.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "PhoenixStorybook",
      source_ref: "v#{@version}",
      source_url: "https://github.com/phenixdigital/phoenix_storybook",
      extra_section: "GUIDES",
      extras: extras(),
      nest_modules_by_prefix: [PhoenixStorybook]
    ]
  end

  defp extras do
    [
      "guides/components.md",
      "guides/icons.md",
      "guides/sandboxing.md",
      "guides/setup.md",
      "guides/theming.md"
    ]
  end

  defp package do
    [
      maintainers: ["Christian Blavier"],
      files: ~w(mix.exs priv lib guides README.md LICENSE.md CHANGELOG.md CONTRIBUTING.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/phenixdigital/phoenix_storybook"}
    ]
  end

  defp aliases do
    [
      coverage: "coveralls.lcov",
      "assets.watch": "cmd npm run watch --prefix assets",
      "assets.build": [
        "cmd npm run build --prefix assets",
        "phx.digest",
        "phx.digest.clean"
      ],
      publish: [
        "assets.build",
        "hex.publish"
      ]
    ]
  end
end
