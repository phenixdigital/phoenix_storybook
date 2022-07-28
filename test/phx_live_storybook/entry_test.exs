defmodule PhxLiveStorybook.EntryTest do
  use ExUnit.Case

  test "component entry default behaviors" do
    defmodule MyComponentEntry do
      use PhxLiveStorybook.Entry, :component
      def component, do: nil
      def function, do: nil
    end

    assert MyComponentEntry.name() == "My Component Entry"
    assert MyComponentEntry.variations() == []
    assert MyComponentEntry.storybook_type() == :component
    assert MyComponentEntry.description() == ""
    assert MyComponentEntry.icon() == nil
  end

  test "live_component entry default behaviors" do
    defmodule MyLiveEntry do
      use PhxLiveStorybook.Entry, :live_component
      def component, do: nil
    end

    assert MyLiveEntry.name() == "My Live Entry"
    assert MyLiveEntry.variations() == []
    assert MyLiveEntry.storybook_type() == :live_component
    assert MyLiveEntry.description() == ""
    assert MyLiveEntry.icon() == nil
  end

  test "page entry default behaviors" do
    defmodule MyPageEntry do
      use PhxLiveStorybook.Entry, :page
      def component, do: nil
    end

    assert MyPageEntry.name() == "My Page Entry"
    assert MyPageEntry.storybook_type() == :page
    assert MyPageEntry.description() == ""
    assert MyPageEntry.icon() == nil
    assert MyPageEntry.navigation() == []
    assert MyPageEntry.render(%{}) == false
  end
end
