defmodule PhxLiveStorybook.ExtraAssignsHelpersTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.{Attr, ComponentEntry}

  import PhxLiveStorybook.ExtraAssignsHelpers

  describe "handle_set_variation_assign/3" do
    setup :entry

    test "with flat mode", %{entry: entry} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "attribute" => "foo"},
               %{},
               entry,
               :flat
             ) ==
               {:variation_id, %{attribute: "foo"}}
    end

    test "with nested mode", %{entry: entry} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "attribute" => "foo"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{attribute: "foo"}}
    end

    test "with typed attributes", %{entry: entry} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "true"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{boolean: true}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => "42"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => 42},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{integer: 42}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => "42.2"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => 42.2},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{float: 42.2}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => "foo"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{atom: :foo}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "list" => ["foo", "bar"]},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{list: ["foo", "bar"]}}
    end

    test "with mismatching typed attributes", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "boolean" => :maybe},
          %{variation_id: %{}},
          entry,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "integer" => "forty-two"},
          %{variation_id: %{}},
          entry,
          :nested
        )
      end

      assert_raise RuntimeError, ~r/type mismatch in assign/, fn ->
        handle_set_variation_assign(
          %{"variation_id" => "variation_id", "float" => :foo},
          %{variation_id: %{}},
          entry,
          :nested
        )
      end
    end

    test "with nil typed attributes", %{entry: entry} do
      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "boolean" => "nil"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{boolean: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "integer" => nil},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{integer: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "float" => nil},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{float: nil}}

      assert handle_set_variation_assign(
               %{"variation_id" => "variation_id", "atom" => nil},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{atom: nil}}
    end

    test "with with invalid param", %{entry: entry} do
      assert_raise RuntimeError, ~r/missing variation_id in assign/, fn ->
        handle_set_variation_assign(%{}, %{}, entry, :flat)
      end
    end
  end

  describe "handle_toggle_variation_assign/3" do
    setup :entry

    test "with flat mode", %{entry: entry} do
      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{},
               entry,
               :flat
             ) ==
               {:variation_id, %{attribute: true}}

      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{attribute: true},
               entry,
               :flat
             ) ==
               {:variation_id, %{attribute: false}}
    end

    test "type mismatch with existing assign", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        assert handle_toggle_variation_assign(
                 %{"variation_id" => "variation_id", "attr" => "attribute"},
                 %{attribute: "false"},
                 entry,
                 :flat
               ) ==
                 {:variation_id, %{attribute: true}}
      end
    end

    test "type mismatch with declared attribute", %{entry: entry} do
      assert_raise RuntimeError, ~r/type mismatch in toggle/, fn ->
        handle_toggle_variation_assign(
          %{"variation_id" => "variation_id", "attr" => "integer"},
          %{},
          entry,
          :flat
        )
      end
    end

    test "with nested mode", %{entry: entry} do
      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{variation_id: %{}},
               entry,
               :nested
             ) ==
               {:variation_id, %{attribute: true}}

      assert handle_toggle_variation_assign(
               %{"variation_id" => "variation_id", "attr" => "attribute"},
               %{variation_id: %{attribute: true}},
               entry,
               :nested
             ) ==
               {:variation_id, %{attribute: false}}
    end

    test "with with invalid param", %{entry: entry} do
      assert_raise RuntimeError, ~r/missing attr in toggle/, fn ->
        handle_toggle_variation_assign(%{}, %{}, entry, :flat)
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
