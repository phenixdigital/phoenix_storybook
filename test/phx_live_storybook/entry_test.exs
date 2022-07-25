defmodule PhxLiveStorybook.EntryTest do
  use ExUnit.Case

  test "component entry default behaviors" do
    defmodule MyEntry do
      use PhxLiveStorybook.Entry, :component
      def component, do: nil
      def function, do: nil
    end

    assert MyEntry.name() == "My Entry"
    assert MyEntry.variations() == []
    assert MyEntry.storybook_type() == :component
    assert MyEntry.description() == ""
    assert MyEntry.icon() == nil
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
end
