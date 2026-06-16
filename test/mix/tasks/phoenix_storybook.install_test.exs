defmodule Mix.Tasks.PhoenixStorybook.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "mix phoenix_storybook.install" do
    test "generates the storybook backend module" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_creates("lib/test_web/storybook.ex", """
      defmodule TestWeb.Storybook do
        use PhoenixStorybook,
          otp_app: :test,
          content_path: Path.expand("../../storybook", __DIR__),
          # assets path are remote path, not local file-system paths
          css_path: "/assets/css/storybook.css",
          js_path: "/assets/js/storybook.js",
          # Ex: "https://github.com/my-org/my-app/blob/main"
          # source_permalink_base_url: "https://github.com/my-org/my-app/blob/main",
          sandbox_class: "test"
      end
      """)
    end

    test "generates the storybook assets and scaffolding" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_creates(igniter, "assets/js/storybook.js")
      assert_creates(igniter, "assets/css/storybook.css")
      assert_creates(igniter, "storybook/_root.index.exs")
      assert_creates(igniter, "storybook/welcome.story.exs")
    end

    test "generates stories for the core components defined in the project" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_creates(igniter, "storybook/core_components/_core_components.index.exs")
      assert_creates(igniter, "storybook/core_components/button.story.exs")
      assert_creates(igniter, "storybook/core_components/flash.story.exs")
      assert_creates(igniter, "storybook/core_components/icon.story.exs")
    end

    test "copies app.css into storybook.css" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      content =
        igniter.rewrite
        |> Rewrite.source!("assets/css/storybook.css")
        |> Rewrite.Source.get(:content)

      assert content =~ ~s|@plugin "../vendor/heroicons";|
      assert content =~ ~s|@source "../../storybook";|
    end

    test "mounts the storybook in the router" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch("lib/test_web/router.ex", """
      + | import PhoenixStorybook.Router
      """)
      |> assert_has_patch("lib/test_web/router.ex", """
      + | scope "/" do
      + |   storybook_assets()
      + | end
      """)
      |> assert_has_patch("lib/test_web/router.ex", """
      + | live_storybook("/storybook", backend_module: TestWeb.Storybook)
      """)
    end

    test "adds the sandbox class to the root layout body" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch("lib/test_web/components/layouts/root.html.heex", """
      - |  <body>
      + |  <body class="test">
      """)
    end

    test "appends the sandbox class to an existing body class" do
      layout_path = "lib/test_web/components/layouts/root.html.heex"

      phx_test_project()
      |> Igniter.update_file(layout_path, fn source ->
        content = Rewrite.Source.get(source, :content)
        content = String.replace(content, "<body>", ~s|<body class="bg-white antialiased">|)
        Rewrite.Source.update(source, :content, content)
      end)
      |> apply_igniter!()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch(layout_path, """
      - |  <body class="bg-white antialiased">
      + |  <body class="bg-white antialiased test">
      """)
    end

    test "falls back to a notice when the body class is dynamic" do
      layout_path = "lib/test_web/components/layouts/root.html.heex"

      igniter =
        phx_test_project()
        |> Igniter.update_file(layout_path, fn source ->
          content = Rewrite.Source.get(source, :content)
          content = String.replace(content, "<body>", "<body class={@class}>")
          Rewrite.Source.update(source, :content, content)
        end)
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_unchanged(igniter, [layout_path])
      assert Enum.any?(igniter.notices, &(&1 =~ "Add the CSS sandbox class"))
    end

    test "adds the storybook esbuild entry point and tailwind profile" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch("config/config.exs", """
      + | ~w(js/app.js js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
      """)
      |> assert_has_patch("config/config.exs", """
      + | storybook: [
      """)
    end

    test "adds the storybook watcher and live_reload pattern to dev.exs" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch("config/dev.exs", """
      + | storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]}
      """)
      |> assert_has_patch("config/dev.exs", """
      + | ~r"storybook/.*\\.exs$"
      """)
    end

    test "configures the formatter" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch(".formatter.exs", """
      + | import_deps: [:phoenix_storybook
      """)
      |> assert_has_patch(".formatter.exs", """
      + | "storybook/**/*.exs"
      """)
    end

    test "adds the storybook tailwind build to the mix aliases" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_has_patch("mix.exs", """
      + | "assets.build": ["compile", "tailwind test", "esbuild test", "tailwind storybook"],
      """)
      |> assert_has_patch("mix.exs", """
      + | "tailwind storybook --minify",
        | "phx.digest"
      """)
    end

    test "is idempotent" do
      phx_test_project()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_unchanged([
        "lib/test_web/router.ex",
        "lib/test_web/storybook.ex",
        "lib/test_web/components/layouts/root.html.heex",
        "config/config.exs",
        "config/dev.exs",
        ".formatter.exs",
        "mix.exs",
        "assets/js/storybook.js",
        "assets/css/storybook.css",
        "storybook/welcome.story.exs"
      ])
    end

    test "with --no-tailwind it skips the tailwind specific setup" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", ["--no-tailwind"])

      assert_creates(igniter, "assets/css/storybook.css")

      refute igniter
             |> Igniter.Test.diff(only: "config/dev.exs")
             |> String.contains?("storybook_tailwind")

      refute igniter
             |> Igniter.Test.diff(only: "config/config.exs")
             |> String.contains?("storybook: [")

      refute igniter
             |> Igniter.Test.diff(only: "mix.exs")
             |> String.contains?("tailwind storybook")
    end
  end
end
