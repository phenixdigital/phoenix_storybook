defmodule PhxLiveStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.Attr
  alias PhxLiveStorybook.Story.{ComponentBehaviour, StoryBehaviour}
  import PhxLiveStorybook.ExtraAssignsHelpers

  setup_all do
    Mox.defmock(StoryMock, for: [StoryBehaviour, ComponentBehaviour])
    :ok
  end

  describe "handle_set_variation_assign/3" do
    setup :story

    test "with flat mode", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "attribute" => "foo"},
               %{},
               story,
               :flat
             ) ==
               {:variation_id, %{attribute: "foo"}}
    end

    test "with nested mode", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "attribute" => "foo"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{attribute: "foo"}}
    end

    test "with typed attributes", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "true"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{boolean: true}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => "42"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => 42},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => "42.2"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => 42.2},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => "foo"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{atom: :foo}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "list" => ["foo", "bar"]},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{list: ["foo", "bar"]}}
    end

    test "with mismatching typed attributes", %{story: story} do
      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "boolean" => :maybe},
          %{variation_id: %{}},
          story,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "integer" => "forty-two"},
          %{variation_id: %{}},
          story,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "float" => :foo},
          %{variation_id: %{}},
          story,
          :nested
        )
      end
    end

    test "with nil typed attributes", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "nil"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{boolean: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => nil},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{integer: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => nil},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{float: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => nil},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{atom: nil}}
    end

    test "with with invalid param", %{story: story} do
      assert_raise RuntimeError, ~r/missing variation_id in assign/, fn ->
        handle_set_variation_assign(%{}, %{}, story, :flat)
      end
    end
  end

  describe "handle_toggle_variation_assign/3" do
    setup :story

    test "with flat mode", %{story: story} do
      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{},
               story,
               :flat
             ) ==
               {:variation_id, %{attribute: true}}

      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{attribute: true},
               story,
               :flat
             ) ==
               {:variation_id, %{attribute: false}}
    end

    test "type mismatch with existing assign", %{story: story} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        assert handle_toggle_variation_assign(
                 %{"variation_id" => "variation_id", "attr" => "attribute"},
                 %{attribute: "false"},
                 story,
                 :flat
               ) ==
                 {:variation_id, %{attribute: true}}
      end
    end

    test "type mismatch with declared attribute", %{story: story} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        handle_toggle_variation_assign(
          %{"variation_id" => "variation_id", "attr" => "integer"},
          %{},
          story,
          :flat
        )
      end
    end

    test "with nested mode", %{story: story} do
      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{variation_id: %{}},
               story,
               :nested
             ) ==
               {:variation_id, %{attribute: true}}

      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{variation_id: %{attribute: true}},
               story,
               :nested
             ) ==
               {:variation_id, %{attribute: false}}
    end

    test "with with invalid param", %{story: story} do
      assert_raise RuntimeError, ~r/missing attr in toggle/, fn ->
        handle_toggle_variation_assign(%{}, %{}, story, :flat)
      end
    end
  end

  defp story(_context) do
    Mox.stub_with(StoryMock, PhxLiveStorybook.ComponentStub)

    Mox.stub(StoryMock, :attributes, fn ->
      [
        %Attr{id: :boolean, type: :boolean},
        %Attr{id: :integer, type: :integer},
        %Attr{id: :float, type: :float},
        %Attr{id: :atom, type: :atom},
        %Attr{id: :list, type: :list}
      ]
    end)

    [story: StoryMock]
  end
end
