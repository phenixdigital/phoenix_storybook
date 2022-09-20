defmodule PhxLiveStorybook.StoryTest do
  use ExUnit.Case, async: true

  test "component story default behaviors" do
    defmodule MyComponentEntry do
      use PhxLiveStorybook.Story, :component
      def function, do: nil
    end

    assert MyComponentEntry.name() == "My Component Entry"
    assert MyComponentEntry.variations() == []
    assert MyComponentEntry.storybook_type() == :component
    assert MyComponentEntry.description() == nil
    assert MyComponentEntry.icon() == nil
  end

  test "live_component story default behaviors" do
    defmodule MyLiveStory do
      use PhxLiveStorybook.Story, :live_component
      def component, do: nil
    end

    assert MyLiveStory.name() == "My Live Story"
    assert MyLiveStory.variations() == []
    assert MyLiveStory.storybook_type() == :live_component
    assert MyLiveStory.description() == nil
    assert MyLiveStory.icon() == nil
  end

  test "page story default behaviors" do
    defmodule MyPageEntry do
      use PhxLiveStorybook.Story, :page
      def component, do: nil
    end

    assert MyPageEntry.name() == "My Page Entry"
    assert MyPageEntry.storybook_type() == :page
    assert MyPageEntry.description() == nil
    assert MyPageEntry.icon() == nil
    assert MyPageEntry.navigation() == []
    assert MyPageEntry.render(%{}) == false
  end
end
