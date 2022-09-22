defmodule PhxLiveStorybook.StoryTest do
  use ExUnit.Case, async: true

  test "component story default behaviors" do
    defmodule MyComponent do
      use PhxLiveStorybook.Story, :component
      def function, do: nil
    end

    assert MyComponent.storybook_type() == :component
    assert MyComponent.description() == nil
    assert MyComponent.variations() == []
  end

  test "live_component story default behaviors" do
    defmodule MyLiveComponent do
      use PhxLiveStorybook.Story, :live_component
      def component, do: nil
    end

    assert MyLiveComponent.storybook_type() == :live_component
    assert MyLiveComponent.description() == nil
    assert MyLiveComponent.variations() == []
  end

  test "page story default behaviors" do
    defmodule MyPage do
      use PhxLiveStorybook.Story, :page
    end

    assert MyPage.storybook_type() == :page
    assert MyPage.description() == nil
    assert MyPage.navigation() == []
    assert MyPage.render(%{}) == false
  end
end
