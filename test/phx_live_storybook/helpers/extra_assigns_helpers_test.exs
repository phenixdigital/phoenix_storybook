defmodule PhxLiveStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.Stories.Attr
  alias PhxLiveStorybook.Story.{ComponentBehaviour, StoryBehaviour}
  import PhxLiveStorybook.ExtraAssignsHelpers

  setup_all do
    Mox.defmock(StoryMock, for: [StoryBehaviour, ComponentBehaviour])
    :ok
  end

  describe "handle_set_variation_assign/3" do
    setup :story

    test "with nested mode", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "attribute" => "foo"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{attribute: "foo"}}
    end

    test "with typed attributes", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "true"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{boolean: true}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => "42"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => 42},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => "42.2"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => 42.2},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => "foo"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{atom: :foo}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "list" => ["foo", "bar"]},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{list: ["foo", "bar"]}}
    end

    test "with mismatching typed attributes", %{story: story} do
      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "boolean" => :maybe},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "integer" => "forty-two"},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "float" => :foo},
          %{{:single, :variation_id} => %{}},
          story
        )
      end
    end

    test "with nil typed attributes", %{story: story} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "nil"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{boolean: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => nil},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{integer: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => nil},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{float: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => nil},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{atom: nil}}
    end

    test "with with invalid param", %{story: story} do
      assert_raise RuntimeError, ~r/missing variation_id in assign/, fn ->
        handle_set_variation_assign(%{}, %{}, story)
      end
    end
  end

  describe "handle_toggle_variation_assign/3" do
    setup :story

    test "with nested mode", %{story: story} do
      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{attribute: true}}

      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{{:single, :variation_id} => %{attribute: true}},
               story
             ) ==
               {{:single, :variation_id}, %{attribute: false}}
    end

    test "with with invalid param", %{story: story} do
      assert_raise RuntimeError, ~r/missing attr in toggle/, fn ->
        handle_toggle_variation_assign(%{}, %{}, story)
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
