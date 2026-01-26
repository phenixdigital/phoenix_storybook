defmodule PhoenixStorybook.Stories.StorySourceTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.Stories.StorySource
  alias PhoenixStorybook.TreeStorybook

  describe "__module_source__/0" do
    test "it returns module source" do
      {:ok, story} = TreeStorybook.load_story("/component")
      source = story.__module_source__()
      assert source =~ ~s|defmodule Component do|
      assert source =~ ~s|def component(assigns) do|
      assert source =~ ~s|def unrelated_function|
      assert source =~ ~s|use Phoenix.Component|
    end

    @tag :capture_log
    test "it fails gracefully if source cannot be loaded" do
      defmodule SourceFailStory do
        use PhoenixStorybook.Story, :component
        import Phoenix.Component
        def function, do: &SourceFailStory.badge/1
        def badge(assigns), do: ~H"<span>Hello World</span>"
      end

      assert is_nil(SourceFailStory.__module_source__())
    end

    test "it returns nil when component definition has multiple clauses" do
      module =
        Module.concat(
          __MODULE__,
          "MultiClauseStory#{System.unique_integer([:positive])}"
        )

      Module.create(
        module,
        quote do
          use PhoenixStorybook.Story, :component
          def function(), do: &__MODULE__.render/1
          def function(), do: &__MODULE__.render/1
          def render(_assigns), do: "ok"
        end,
        Macro.Env.location(__ENV__)
      )

      assert is_nil(module.__module_source__())
    end
  end

  describe "__source__/0" do
    test "it returns story.exs source code" do
      {:ok, story} = TreeStorybook.load_story("/component")
      assert story.__source__() =~ File.read!(tree_fixture_path("component.story.exs"))
    end
  end

  describe "__extra_sources__/0" do
    test "it returns a list of all story's extra sources" do
      {:ok, story} = TreeStorybook.load_story("/examples/example")
      path1 = tree_fixture_path("examples/example_html.ex")
      path2 = tree_fixture_path("examples/templates/example.html.heex")

      assert story.__extra_sources__() == %{
               "./example_html.ex" => File.read!(path1),
               "./templates/example.html.heex" => File.read!(path2)
             }
    end

    test "it logs and returns an empty map when extra_sources fails" do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          module =
            Module.concat(
              __MODULE__,
              "ExtraSourcesFailStory#{System.unique_integer([:positive])}"
            )

          Module.create(
            module,
            quote do
              use PhoenixStorybook.Story, :example
              def extra_sources, do: raise("boom")
            end,
            Macro.Env.location(__ENV__)
          )

          assert module.__extra_sources__() == %{}
        end)

      assert log =~ "cannot load extra sources for story"
    end
  end

  describe "__file_path__/0" do
    test "it returns story.exs file path" do
      {:ok, story} = TreeStorybook.load_story("/component")
      assert story.__file_path__() =~ tree_fixture_path("component.story.exs")
    end
  end

  describe "strip_function_source" do
    test "it extracts function from module source" do
      {:ok, story} = TreeStorybook.load_story("/component")
      module_source = story.__module_source__()
      source = StorySource.strip_function_source(module_source, story.function())
      assert source =~ ~s|defmodule Component do|
      assert source =~ ~s|def component(assigns) do|
      refute source =~ ~s|def unrelated_function|
      refute source =~ ~s|use Phoenix.Component|
      refute source =~ ~s|attr :index2|
      refute source =~ ~s|should not appear|
    end

    test "it handles the last function in a module" do
      source_path = PhoenixStorybook.Mount.__info__(:compile)[:source] |> to_string()
      module_source = File.read!(source_path)

      source =
        StorySource.strip_function_source(module_source, &PhoenixStorybook.Mount.on_mount/4)

      assert source =~ "def on_mount"
    end

    test "it raises when docs have non-integer locations" do
      source_path = :telemetry.module_info(:compile)[:source] |> to_string()
      module_source = File.read!(source_path)

      assert_raise FunctionClauseError, fn ->
        StorySource.strip_function_source(module_source, &:telemetry.execute/3)
      end
    end
  end

  defp tree_fixture_path(path) do
    Path.expand("../../fixtures/storybook_content/tree/" <> path, __DIR__)
  end
end
