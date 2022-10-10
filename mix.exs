defmodule PhxLiveStorybook.MixProject do
  use Mix.Project

  @version "0.4.3"

  def project do
    [
      app: :phx_live_storybook,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      config_path: "./config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "phx_live_storybook",
      description: "A pluggable storybook for your LiveView components.",
      source_url: "https://github.com/phenixdigital/phx_live_storybook",
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
        plt_file: {:no_warn, ".plts/storybook.plt"}
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
      {:phoenix_live_view, "~> 0.18"},
      {:makeup_eex, "~> 0.1.0"},
      {:heroicons, "~> 0.5", optional: true},
      {:jason, "~> 1.3", optional: true},
      {:earmark, "~> 1.4", runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:floki, "~> 0.33.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
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
      links: %{"GitHub" => "https://github.com/phenixdigital/phx_live_storybook"}
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
