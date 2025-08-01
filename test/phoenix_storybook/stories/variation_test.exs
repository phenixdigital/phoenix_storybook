defmodule PhoenixStorybook.Stories.VariationTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.Stories.{Variation, VariationGroup}

  describe "Variation struct" do
    test "can be created with required fields only" do
      variation = %Variation{id: :test}

      assert variation.id == :test
      assert variation.description == nil
      assert variation.note == nil
      assert variation.let == nil
      assert variation.slots == []
      assert variation.attributes == %{}
      assert variation.template == :unset
    end

    test "can be created with all fields including note" do
      variation = %Variation{
        id: :test,
        description: "Test variation",
        note: "This is a **test note** with `code`.",
        let: :item,
        slots: ["<:slot>content</:slot>"],
        attributes: %{label: "Test"},
        template: "<div>test</div>"
      }

      assert variation.id == :test
      assert variation.description == "Test variation"
      assert variation.note == "This is a **test note** with `code`."
      assert variation.let == :item
      assert variation.slots == ["<:slot>content</:slot>"]
      assert variation.attributes == %{label: "Test"}
      assert variation.template == "<div>test</div>"
    end

    test "note field accepts markdown content" do
      markdown_note = """
      This variation demonstrates:

      - **Bold text**
      - *Italic text*
      - `Inline code`

      ```elixir
      %Variation{
        id: :example,
        note: "markdown content"
      }
      ```
      """

      variation = %Variation{
        id: :markdown_test,
        note: markdown_note
      }

      assert variation.note == markdown_note
    end

    test "note field can be nil" do
      variation = %Variation{id: :no_note}
      assert variation.note == nil
    end
  end

  describe "VariationGroup struct" do
    test "can be created with required fields only" do
      variations = [
        %Variation{id: :first},
        %Variation{id: :second}
      ]

      group = %VariationGroup{
        id: :test_group,
        variations: variations
      }

      assert group.id == :test_group
      assert group.description == nil
      assert group.note == nil
      assert group.variations == variations
      assert group.template == :unset
    end

    test "can be created with all fields including note" do
      variations = [
        %Variation{id: :first},
        %Variation{id: :second}
      ]

      group = %VariationGroup{
        id: :test_group,
        description: "Test group",
        note: "This group shows **different options** for the component.",
        variations: variations,
        template: "<div>group template</div>"
      }

      assert group.id == :test_group
      assert group.description == "Test group"
      assert group.note == "This group shows **different options** for the component."
      assert group.variations == variations
      assert group.template == "<div>group template</div>"
    end

    test "note field accepts markdown content for groups" do
      markdown_note = """
      # Group Overview

      This variation group contains:

      1. Primary button variant
      2. Secondary button variant
      3. Disabled button variant

      ## Usage Example

      ```elixir
      %VariationGroup{
        id: :button_variants,
        note: "markdown content",
        variations: [...]
      }
      ```
      """

      group = %VariationGroup{
        id: :group_with_markdown,
        note: markdown_note,
        variations: [%Variation{id: :test}]
      }

      assert group.note == markdown_note
    end

    test "can mix variations with and without notes" do
      variations = [
        %Variation{
          id: :with_note,
          note: "This variation has a note."
        },
        %Variation{
          id: :without_note
        },
        %Variation{
          id: :with_markdown_note,
          note: "This has **markdown** and `code`."
        }
      ]

      group = %VariationGroup{
        id: :mixed_notes,
        note: "This group has mixed note usage.",
        variations: variations
      }

      assert length(group.variations) == 3
      assert Enum.at(group.variations, 0).note == "This variation has a note."
      assert Enum.at(group.variations, 1).note == nil
      assert Enum.at(group.variations, 2).note == "This has **markdown** and `code`."
    end

    test "enforces required fields" do
      # Should raise when missing required :id
      assert_raise ArgumentError, fn ->
        struct!(VariationGroup, %{variations: []})
      end

      # Should raise when missing required :variations
      assert_raise ArgumentError, fn ->
        struct!(VariationGroup, %{id: :test})
      end
    end
  end

  describe "pattern matching" do
    test "can pattern match on variation with note" do
      variation = %Variation{
        id: :test,
        description: "Test",
        note: "Test note"
      }

      case variation do
        %Variation{id: id, note: note} when not is_nil(note) ->
          assert id == :test
          assert note == "Test note"

        _ ->
          flunk("Should match variation with note")
      end
    end

    test "can pattern match on variation without note" do
      variation = %Variation{id: :test}

      case variation do
        %Variation{id: id, note: nil} ->
          assert id == :test

        _ ->
          flunk("Should match variation without note")
      end
    end

    test "can pattern match on variation group with note" do
      group = %VariationGroup{
        id: :test_group,
        note: "Group note",
        variations: [%Variation{id: :test}]
      }

      case group do
        %VariationGroup{id: id, note: note} when not is_nil(note) ->
          assert id == :test_group
          assert note == "Group note"

        _ ->
          flunk("Should match variation group with note")
      end
    end
  end
end
