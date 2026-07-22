defmodule Mix.Tasks.PhoenixStorybook.InstallTest do
  use ExUnit.Case, async: false

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
          # asset paths are URL paths (served by your app), not local file-system paths
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
      |> assert_has_patch("config/config.exs", """
      + | env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
      """)
    end

    test "omits the storybook tailwind NODE_PATH env when the app has no colocated CSS" do
      config =
        phx_test_project()
        |> edit_file("assets/css/app.css", ~r/.*phoenix-colocated.*\n/, "")
        |> Igniter.compose_task("phoenix_storybook.install", [])
        |> config_content()

      assert config =~ "storybook: ["
      storybook_profile = config |> String.split("storybook: [") |> List.last()
      refute storybook_profile =~ "NODE_PATH"
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

    test "with --no-tailwind it writes the minimal scoped stylesheet, not an app.css copy" do
      content =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", ["--no-tailwind"])
        |> css_content()

      assert content =~ ".test {"
      assert content =~ "font-family: system-ui"
      refute content =~ ~s|@import "tailwindcss"|
      refute content =~ "@plugin"
    end

    test "falls back to the tailwind stylesheet template when there is no app.css" do
      igniter =
        phx_test_project()
        |> Igniter.rm("assets/css/app.css")
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      content = css_content(igniter)

      assert content =~ ~s|@import "tailwindcss" source(none);|
      assert content =~ ~s|@source "../../storybook";|
      refute content =~ "copied from assets/css/app.css at install time"

      assert_has_notice(igniter, &(&1 =~ "loads this file instead of your app.css"))
    end

    test "skips core component stories when there is no CoreComponents module" do
      igniter =
        phx_test_project()
        |> Igniter.rm("lib/test_web/components/core_components.ex")
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_creates(igniter, "lib/test_web/storybook.ex")
      assert_creates(igniter, "storybook/welcome.story.exs")

      refute_creates(igniter, "storybook/core_components/_core_components.index.exs")
      refute_creates(igniter, "storybook/core_components/button.story.exs")
      refute_creates(igniter, "storybook/examples/core_components.story.exs")
    end

    test "warns and patches nothing in the router when no router exists" do
      igniter =
        phx_test_project()
        |> Igniter.rm("lib/test_web/router.ex")
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_warning(igniter, &(&1 =~ "No Phoenix router found"))
      assert_has_notice(igniter, &(&1 =~ "Add a watcher for the storybook tailwind profile"))
      assert_has_notice(igniter, &(&1 =~ "Add a live_reload pattern"))

      assert_creates(igniter, "lib/test_web/storybook.ex")
    end

    test "adds a Dockerfile notice when a Dockerfile is present" do
      igniter =
        phx_test_project(files: %{"Dockerfile" => "FROM elixir:1.17\n"})
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "COPY storybook storybook"))
    end

    test "notices the esbuild setup when esbuild is not configured" do
      igniter =
        phx_test_project()
        |> strip_config(~r/\n# Configure esbuild.*?\n  \]\n/s)
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "Add js/storybook.js as a new entry point"))

      refute igniter
             |> Igniter.Test.diff(only: "config/config.exs")
             |> String.contains?("js/storybook.js")
    end

    test "notices the tailwind setup when tailwind is not configured" do
      igniter =
        phx_test_project()
        |> strip_config(~r/\n# Configure tailwind.*?\n  \]\n/s)
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "Add a tailwind build profile"))

      assert_has_notice(
        igniter,
        &(&1 =~
            ~S|env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}|)
      )

      refute igniter
             |> Igniter.Test.diff(only: "config/config.exs")
             |> String.contains?("storybook: [")
    end

    test "notices the esbuild setup when the profile has no js/app.js entry point" do
      igniter =
        phx_test_project()
        |> edit_file("config/config.exs", "js/app.js", "js/main.js")
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "Add js/storybook.js as a new entry point"))

      refute igniter
             |> Igniter.Test.diff(only: "config/config.exs")
             |> String.contains?("js/storybook.js")
    end

    test "notices the sandbox class when there is no root layout" do
      layout_path = "lib/test_web/components/layouts/root.html.heex"

      igniter =
        phx_test_project()
        |> Igniter.rm(layout_path)
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "Add the CSS sandbox class"))
      refute_creates(igniter, layout_path)
    end

    test "notices the live_reload setup when there is no dev.exs" do
      # --no-tailwind, otherwise the tailwind watcher setup recreates dev.exs
      # before the live_reload step runs.
      igniter =
        phx_test_project()
        |> Igniter.rm("config/dev.exs")
        |> apply_igniter!()
        |> Igniter.compose_task("phoenix_storybook.install", ["--no-tailwind"])

      assert_has_notice(igniter, &(&1 =~ "Add a live_reload pattern"))
    end

    test "warns the live_reload setup when dev.exs has no live_reload config" do
      igniter =
        phx_test_project()
        |> edit_file("config/dev.exs", ~r/\n# Reload browser tabs.*?\n  \]\n/s, "\n")
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_warning(igniter, &(&1 =~ "Add a live_reload pattern"))

      refute igniter
             |> Igniter.Test.diff(only: "config/dev.exs")
             |> String.contains?("storybook/.*")
    end

    test "appends the storybook build to assets.deploy when it has no phx.digest" do
      igniter =
        phx_test_project()
        |> edit_file("mix.exs", ~r/,\n\s*"phx\.digest"/, "")
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert igniter
             |> Igniter.Test.diff(only: "mix.exs")
             |> String.contains?("tailwind storybook --minify")
    end

    test "generates the example core components story when all example functions exist" do
      # The fixture's CoreComponents has button/header/table/input but no
      # simple_form, so add it to satisfy the example story's full set.
      phx_test_project()
      |> edit_file(
        "lib/test_web/components/core_components.ex",
        "defmodule TestWeb.CoreComponents do",
        "defmodule TestWeb.CoreComponents do\n  def simple_form(assigns), do: nil\n"
      )
      |> Igniter.compose_task("phoenix_storybook.install", [])
      |> assert_creates("storybook/examples/core_components.story.exs")
    end

    test "notices that storybook.css must be kept in sync with app.css" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("phoenix_storybook.install", [])

      assert_has_notice(igniter, &(&1 =~ "mirror the relevant changes"))
      assert_has_notice(igniter, &(&1 =~ "nest it under your CSS sandbox class"))
    end
  end

  defp css_content(igniter) do
    igniter.rewrite
    |> Rewrite.source!("assets/css/storybook.css")
    |> Rewrite.Source.get(:content)
  end

  defp config_content(igniter) do
    igniter.rewrite
    |> Rewrite.source!("config/config.exs")
    |> Rewrite.Source.get(:content)
  end

  defp strip_config(igniter, regex) do
    edit_file(igniter, "config/config.exs", regex, "\n")
  end

  defp edit_file(igniter, path, from, to) do
    igniter
    |> Igniter.update_file(path, fn source ->
      content = source |> Rewrite.Source.get(:content) |> String.replace(from, to)
      Rewrite.Source.update(source, :content, content)
    end)
    |> apply_igniter!()
  end
end
