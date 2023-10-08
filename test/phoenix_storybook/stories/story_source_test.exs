defmodule PhoenixStorybook.Stories.StorySourceTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.TreeStorybook

  describe "__component_source__/0" do
    test "it returns component source" do
      {:ok, story} = TreeStorybook.load_story("/component")
      assert story.__component_source__() =~ ~s|defmodule Component do|
    end

    @tag :capture_log
    test "it fails gracefully if source cannot be loaded" do
      defmodule SourceFailStory do
        use PhoenixStorybook.Story, :component
        import Phoenix.Component
        def function, do: &SourceFailStory.badge/1
        def badge(assigns), do: ~H"<span>Hello World</span>"
      end

      assert is_nil(SourceFailStory.__component_source__())
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
  end

  describe "__file_path__/0" do
    test "it returns story.exs file path" do
      {:ok, story} = TreeStorybook.load_story("/component")
      assert story.__file_path__() =~ tree_fixture_path("component.story.exs")
    end
  end

  defp tree_fixture_path(path) do
    Path.expand("../../fixtures/storybook_content/tree/" <> path, __DIR__)
  end
end
