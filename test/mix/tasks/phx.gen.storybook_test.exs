Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.StorybookTest do
  use ExUnit.Case
  import PhoenixStorybook.MixHelper
  alias Mix.Tasks.Phx.Gen.Storybook
  alias PhoenixStorybook.ExsCompiler

  setup do
    Mix.Task.clear()
    :ok
  end

  @tag :capture_log
  test "mix phx.gen.storybook generates a working storybook", config do
    in_tmp_project(config.test, fn ->
      File.touch("Dockerfile")

      for _ <- 1..11, do: send(self(), {:mix_shell_input, :yes?, true})
      Storybook.run([])

      [{index, _}] = Code.compile_file("storybook/_root.index.exs")
      assert index.folder_icon() == {:fa, "book-open", :light, "psb:mr-1"}

      [{page, _}] = Code.compile_file("storybook/welcome.story.exs")
      assert page.storybook_type() == :page

      [{backend, _}] = Code.compile_file("lib/phoenix_storybook_web/storybook.ex")
      assert backend.config(:otp_app) == :phoenix_storybook
      assert backend.config(:sandbox_class) == "phoenix-storybook"

      assert_file("assets/js/storybook.js")

      assert_file("assets/css/storybook.css", fn file ->
        assert String.contains?(file, ~s|@import "tailwindcss" source(none)|)
        assert String.contains?(file, ~s|@source "../../lib/phoenix_storybook_web"|)
        assert String.contains?(file, ~s|@source "../../storybook"|)
        refute String.contains?(file, ~s|@import "tailwindcss/base|)
      end)

      assert_shell_receive(:info, ~r|Starting storybook generation|)
      assert_shell_receive(:info, ~r|creating lib/phoenix_storybook_web/storybook.ex|)
      assert_shell_receive(:info, ~r|creating storybook/_root.index.exs|)
      assert_shell_receive(:info, ~r|creating storybook/welcome.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/button.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/table.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/_core_components.index.exs|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook.css|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook_theme.css|)
      assert_shell_receive(:info, ~r|creating assets/js/storybook.js|)
      assert_shell_receive(:yes?, ~r|Add the following to your.*router.ex.*:|)

      assert_shell_receive(
        :yes?,
        ~r|Add.*js/storybook.js.*as a new entry point to your existing esbuild profile in .*config/config.exs.*|
      )

      assert_receive {:mix_shell, :yes?, [tailwind_profile_msg]}

      assert tailwind_profile_msg =~
               ~r|Add new Tailwind build profiles for.*storybook.css.*storybook_theme.css.*config/config.exs|

      assert String.contains?(tailwind_profile_msg, "--input=assets/css/storybook_theme.css")
      assert String.contains?(tailwind_profile_msg, "--output=priv/static/assets/css/storybook_theme.css")

      assert_shell_receive(
        :yes?,
        ~r|Review the generated.*assets/css/storybook.css|
      )

      assert_shell_receive(
        :yes?,
        ~r|nest it under your CSS sandbox class|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add the CSS sandbox class to your layout in.*lib/phoenix_storybook_web/components/layouts/root.html.heex.*:|
      )

      assert_receive {:mix_shell, :yes?, [watchers_msg]}

      assert watchers_msg =~
               ~r|Add new.*endpoint watchers.*for your new Tailwind build profiles in.*config/dev.exs.*|

      assert String.contains?(watchers_msg, "storybook_theme_tailwind")

      assert_receive {:mix_shell, :yes?, [live_reload_msg]}
      assert live_reload_msg =~ ~r|Add a new.*live_reload pattern.*to your endpoint in.*config/dev.exs|
      assert String.contains?(live_reload_msg, ~S|~r"storybook/.*\.exs$"|)

      assert_shell_receive(:yes?, ~r|Add your storybook content to.*\.formatter.exs.*|)

      assert_receive {:mix_shell, :yes?, [aliases_msg]}
      assert aliases_msg =~ ~r|Add the storybook build to your asset aliases in .*mix.exs|
      assert String.contains?(aliases_msg, "tailwind storybook_theme")

      assert_shell_receive(:yes?, ~r|Add a COPY directive in .*Dockerfile.*|)
      assert_shell_receive(:info, ~r|You are all set! 🚀|)
      assert_shell_receive(:info, ~r|You can run mix phx.server and visit|)
    end)
  end

  @tag :capture_log
  test "mix phx.gen.storybook --no-tailwind generates a working storybook without tailwind",
       config do
    in_tmp_project(config.test, fn ->
      for _ <- 1..6, do: send(self(), {:mix_shell_input, :yes?, true})
      Storybook.run(["--no-tailwind"])

      assert_file("storybook/_root.index.exs")
      assert_file("storybook/welcome.story.exs")
      assert_file("lib/phoenix_storybook_web/storybook.ex")

      assert_file("assets/js/storybook.js")

      assert_file("assets/css/storybook.css", fn file ->
        refute String.contains?(file, ~s|@import "tailwindcss|)
        assert String.contains?(file, ".phoenix-storybook {")
        refute String.contains?(file, ".psb-sandbox")
      end)

      assert_shell_receive(:info, ~r|Starting storybook generation|)
      assert_shell_receive(:info, ~r|creating lib/phoenix_storybook_web/storybook.ex|)
      assert_shell_receive(:info, ~r|creating storybook/_root.index.exs|)
      assert_shell_receive(:info, ~r|creating storybook/welcome.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/button.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/table.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/_core_components.index.exs|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook.css|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook_theme.css|)
      assert_shell_receive(:info, ~r|creating assets/js/storybook.js|)
      assert_shell_receive(:yes?, ~r|Add the following to your.*router.ex.*:|)

      assert_shell_receive(
        :yes?,
        ~r|Add.*js/storybook.js.*as a new entry point to your existing esbuild profile in .*config/config.exs.*|
      )

      assert_receive {:mix_shell, :yes?, [no_tw_css_msg]}

      assert no_tw_css_msg =~
               ~r|Build and serve your storybook stylesheets.*storybook.css.*storybook_theme.css|

      assert String.contains?(no_tw_css_msg, "assets.deploy")

      assert_shell_receive(
        :yes?,
        ~r|Add the CSS sandbox class to your layout in.*lib/phoenix_storybook_web/components/layouts/root.html.heex.*:|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add a new.*live_reload pattern.*to your endpoint in.*config/dev.exs.*|
      )

      assert_shell_receive(:yes?, ~r|Add your storybook content to.*\.formatter.exs.*|)
      assert_shell_receive(:info, ~r|You are all set! 🚀|)
      assert_shell_receive(:info, ~r|You can run mix phx.server and visit|)
    end)
  end

  @tag :capture_log
  test "generated component stories do not contain the Elixir. prefix", config do
    in_tmp_project(config.test, fn ->
      for _ <- 1..10, do: send(self(), {:mix_shell_input, :yes?, true})
      Storybook.run([])

      story_file = "storybook/core_components/button.story.exs"
      story = ExsCompiler.compile_exs!(story_file, "./")
      assert story.storybook_type() == :component
      assert story.function() == (&PhoenixStorybookWeb.CoreComponents.button/1)

      story_content = File.read!(story_file)
      assert story_content =~ "def function, do: &PhoenixStorybookWeb.CoreComponents.button/1"
    end)
  end

  test "abort generator", config do
    in_tmp_project(config.test, fn ->
      send(self(), {:mix_shell_input, :yes?, false})
      Storybook.run([])

      assert_shell_receive(:info, ~r|Starting storybook generation|)
      assert_shell_receive(:info, ~r|creating lib/phoenix_storybook_web/storybook.ex|)
      assert_shell_receive(:info, ~r|creating storybook/_root.index.exs|)
      assert_shell_receive(:info, ~r|creating storybook/welcome.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/button.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/table.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/_core_components.index.exs|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook.css|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook_theme.css|)
      assert_shell_receive(:info, ~r|creating assets/js/storybook.js|)
      assert_shell_receive(:info, ~r|Storybook files were generated\. Setup walkthrough stopped|)
    end)
  end

  test "with wrong flags it fails", config do
    in_tmp_project(config.test, fn ->
      assert_raise Mix.Error, "Invalid option: --unknown-flag", fn ->
        Storybook.run(["--unknown-flag"])
      end
    end)
  end

  defp assert_shell_receive(kind, pattern) do
    assert_receive {:mix_shell, ^kind, [msg]}

    if kind == :info and String.starts_with?(msg, "==> ") do
      assert_shell_receive(kind, pattern)
    else
      assert msg =~ pattern
    end
  end
end

defmodule PhoenixStorybookWeb.CoreComponents do
  use Phoenix.Component
  def button(assigns), do: ~H[]
  def table(assigns), do: ~H[]
end
