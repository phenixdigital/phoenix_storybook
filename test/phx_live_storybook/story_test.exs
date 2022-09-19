defmodule PhxLiveStorybook.StoryTest do
  use ExUnit.Case, async: true

  test "component story default behaviors" do
    defmodule MyComponentStory do
      use PhxLiveStorybook.Story, :component
      def function, do: nil
    end

    assert MyComponentStory.name() == "My Component Story"
    assert MyComponentStory.variations() == []
    assert MyComponentStory.storybook_type() == :component
    assert MyComponentStory.description() == nil
    assert MyComponentStory.icon() == nil
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
    defmodule MyPageStory do
      use PhxLiveStorybook.Story, :page
      def component, do: nil
    end

    assert MyPageStory.name() == "My Page Story"
    assert MyPageStory.storybook_type() == :page
    assert MyPageStory.description() == nil
    assert MyPageStory.icon() == nil
    assert MyPageStory.navigation() == []
    assert MyPageStory.render(%{}) == false
  end
end
