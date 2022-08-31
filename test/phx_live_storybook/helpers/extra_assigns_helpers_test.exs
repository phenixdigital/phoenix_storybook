defmodule PhxLiveStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  import PhxLiveStorybook.ExtraAssignsHelpers

  describe "handle_set_story_assign/3" do
    test "with flat mode" do
      assert handle_set_story_assign("story_id/attribute/foo", %{}, :flat) ==
               {:story_id, %{attribute: "foo"}}
    end

    test "with nested mode" do
      assert handle_set_story_assign("story_id/attribute/foo", %{story_id: %{}}, :nested) ==
               {:story_id, %{attribute: "foo"}}
    end

    test "with with invalid param" do
      assert_raise RuntimeError, ~r/invalid set-story-assign syntax/, fn ->
        handle_set_story_assign("attribute/foo", %{}, :flat)
      end
    end
  end

  describe "handle_toggle_story_assign/3" do
    test "with flat mode" do
      assert handle_toggle_story_assign("story_id/attribute", %{}, :flat) ==
               {:story_id, %{attribute: true}}

      assert handle_toggle_story_assign("story_id/attribute", %{attribute: "true"}, :flat) ==
               {:story_id, %{attribute: false}}
    end

    test "with nested mode" do
      assert handle_toggle_story_assign("story_id/attribute", %{story_id: %{}}, :nested) ==
               {:story_id, %{attribute: true}}

      assert handle_toggle_story_assign(
               "story_id/attribute",
               %{story_id: %{attribute: "true"}},
               :nested
             ) ==
               {:story_id, %{attribute: false}}
    end

    test "with with invalid param" do
      assert_raise RuntimeError, ~r/invalid toggle-story-assign syntax/, fn ->
        handle_toggle_story_assign("attribute", %{}, :flat)
      end
    end
  end
end
