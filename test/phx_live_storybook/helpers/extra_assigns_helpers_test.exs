defmodule PhxLiveStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.{Attr, ComponentEntry}

  import PhxLiveStorybook.ExtraAssignsHelpers

  describe "handle_set_story_assign/3" do
    setup :entry

    test "with flat mode", %{entry: entry} do
      assert handle_set_story_assign(
               %{"story_id" => "story_id", "attribute" => "foo"},
               %{},
               entry,
               :flat
             ) ==
               {:story_id, %{attribute: "foo"}}
    end

    test "with nested mode", %{entry: entry} do
      assert handle_set_story_assign(
               %{"story_id" => "story_id", "attribute" => "foo"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{attribute: "foo"}}
    end

    test "with typed attributes", %{entry: entry} do
      assert handle_set_story_assign(
               %{"story_id" => "story_id", "boolean" => "true"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{boolean: true}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "integer" => "42"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{integer: 42}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "integer" => 42},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{integer: 42}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "float" => "42.2"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{float: 42.2}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "float" => 42.2},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{float: 42.2}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "atom" => "foo"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{atom: :foo}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "list" => ["foo", "bar"]},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{list: ["foo", "bar"]}}
    end

    test "with mismatching typed attributes", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_story_assign(
          %{"story_id" => "story_id", "boolean" => :maybe},
          %{story_id: %{}},
          entry,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_story_assign(
          %{"story_id" => "story_id", "integer" => "forty-two"},
          %{story_id: %{}},
          entry,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_story_assign(
          %{"story_id" => "story_id", "float" => :foo},
          %{story_id: %{}},
          entry,
          :nested
        )
      end
    end

    test "with nil typed attributes", %{entry: entry} do
      assert handle_set_story_assign(
               %{"story_id" => "story_id", "boolean" => "nil"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{boolean: nil}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "integer" => nil},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{integer: nil}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "float" => nil},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{float: nil}}

      assert handle_set_story_assign(
               %{"story_id" => "story_id", "atom" => nil},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{atom: nil}}
    end

    test "with with invalid param", %{entry: entry} do
      assert_raise RuntimeError, ~r/missing story_id in assign/, fn ->
        handle_set_story_assign(%{}, %{}, entry, :flat)
      end
    end
  end

  describe "handle_toggle_story_assign/3" do
    setup :entry

    test "with flat mode", %{entry: entry} do
      assert handle_toggle_story_assign(
               %{"story_id" => "story_id", "attr" => "attribute"},
               %{},
               entry,
               :flat
             ) ==
               {:story_id, %{attribute: true}}

      assert handle_toggle_story_assign(
               %{"story_id" => "story_id", "attr" => "attribute"},
               %{attribute: true},
               entry,
               :flat
             ) ==
               {:story_id, %{attribute: false}}
    end

    test "type mismatch with existing assign", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        assert handle_toggle_story_assign(
                 %{"story_id" => "story_id", "attr" => "attribute"},
                 %{attribute: "false"},
                 entry,
                 :flat
               ) ==
                 {:story_id, %{attribute: true}}
      end
    end

    test "type mismatch with declared attribute", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        handle_toggle_story_assign(
          %{"story_id" => "story_id", "attr" => "integer"},
          %{},
          entry,
          :flat
        )
      end
    end

    test "with nested mode", %{entry: entry} do
      assert handle_toggle_story_assign(
               %{"story_id" => "story_id", "attr" => "attribute"},
               %{story_id: %{}},
               entry,
               :nested
             ) ==
               {:story_id, %{attribute: true}}

      assert handle_toggle_story_assign(
               %{"story_id" => "story_id", "attr" => "attribute"},
               %{story_id: %{attribute: true}},
               entry,
               :nested
             ) ==
               {:story_id, %{attribute: false}}
    end

    test "with with invalid param", %{entry: entry} do
      assert_raise RuntimeError, ~r/missing attr in toggle/, fn ->
        handle_toggle_story_assign(%{}, %{}, entry, :flat)
      end
    end
  end

  defp entry(_context) do
    [
      entry: %ComponentEntry{
        attributes: [
          %Attr{id: :boolean, type: :boolean},
          %Attr{id: :integer, type: :integer},
          %Attr{id: :float, type: :float},
          %Attr{id: :atom, type: :atom},
          %Attr{id: :list, type: :list}
        ]
      }
    ]
  end
end
