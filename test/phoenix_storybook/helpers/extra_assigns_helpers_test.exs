defmodule PhoenixStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.Stories.Attr
  alias PhoenixStorybook.Story.{ComponentBehaviour, StoryBehaviour}
  import PhoenixStorybook.ExtraAssignsHelpers

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
               %{"variation_id" => "variation_id", "atom_with_values" => "opt1"},
               %{{:single, :variation_id} => %{}},
               story
             ) ==
               {{:single, :variation_id}, %{atom_with_values: :opt1}}

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

      assert_raise RuntimeError, ~r/unknown atom value in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "atom" => unknown_string()},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      assert_raise RuntimeError, ~r/unknown atom value in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "atom_with_values" => "unknown"},
          %{{:single, :variation_id} => %{}},
          story
        )
      end
    end

    test "does not intern unknown assign params", %{story: story} do
      unknown_attr = unknown_string()
      unknown_variation = unknown_string()
      unknown_atom_value = unknown_string()

      assert_raise RuntimeError, ~r/unknown attribute in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", unknown_attr => "foo"},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      refute_existing_atom(unknown_attr)

      assert_raise RuntimeError, ~r/unknown variation_id in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => unknown_variation, "attribute" => "foo"},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      refute_existing_atom(unknown_variation)

      assert_raise RuntimeError, ~r/unknown atom value in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "atom" => unknown_atom_value},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      refute_existing_atom(unknown_atom_value)
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

    test "rejects unknown variation ids", %{story: story} do
      assert_raise RuntimeError, ~r/unknown variation_id in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "unknown", "attribute" => "foo"},
          %{{:single, :variation_id} => %{}},
          story
        )
      end
    end

    test "rejects invalid attribute names", %{story: story} do
      assert_raise RuntimeError, ~r/invalid attribute name in assign/, fn ->
        handle_set_variation_assign(
          %{
            "variation_id" => "variation_id",
            ~s|attribute" injected={send(self(), :rce)} bar| => "foo"
          },
          %{{:single, :variation_id} => %{}},
          story
        )
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

    test "does not intern unknown toggle attr", %{story: story} do
      unknown_attr = unknown_string()

      assert_raise RuntimeError, ~r/unknown attribute in toggle/, fn ->
        handle_toggle_variation_assign(
          %{"variation_id" => "variation_id", "attr" => unknown_attr},
          %{{:single, :variation_id} => %{}},
          story
        )
      end

      refute_existing_atom(unknown_attr)
    end
  end

  defp story(_context) do
    Mox.stub_with(StoryMock, PhoenixStorybook.ComponentStub)

    Mox.stub(StoryMock, :attributes, fn ->
      [
        %Attr{id: :boolean, type: :boolean},
        %Attr{id: :integer, type: :integer},
        %Attr{id: :float, type: :float},
        %Attr{id: :atom, type: :atom},
        %Attr{id: :atom_with_values, type: :atom, values: [:opt1, :opt2]},
        %Attr{id: :list, type: :list}
      ]
    end)

    [story: StoryMock]
  end

  defp unknown_string do
    "psb_unknown_#{System.unique_integer([:positive])}"
  end

  defp refute_existing_atom(value) do
    assert_raise ArgumentError, fn -> String.to_existing_atom(value) end
  end
end
