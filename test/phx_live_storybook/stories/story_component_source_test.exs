defmodule PhxLiveStorybook.Stories.StoryComponentSourceTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.TreeStorybook

  describe "__component_source__/0" do
    test "it returns component source" do
      {:ok, story} = TreeStorybook.load_story("/component")
      assert story.__component_source__() =~ ~s|defmodule Component do|
    end

    @tag :capture_log
    test "it fails gracefully if source cannot be loaded" do
      defmodule SourceFailStory do
        use PhxLiveStorybook.Story, :component
        import Phoenix.Component
        def function, do: &badge/1
        defp badge(assigns), do: ~H"<span>Hello World</span>"
      end

      assert is_nil(SourceFailStory.__component_source__())
    end
  end

  describe "__file_path__/0" do
    test "it returns story.exs file path" do
      {:ok, story} = TreeStorybook.load_story("/component")

      assert story.__file_path__() =~
               Path.expand("../../fixtures/storybook_content/tree/component.story.exs", __DIR__)
    end
  end
end
