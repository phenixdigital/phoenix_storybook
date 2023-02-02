defmodule PhoenixStorybook.StoryTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.Stories.{Attr, Slot}

  describe "component story" do
    test "component story default behaviors" do
      defmodule MyComponentStory do
        use PhoenixStorybook.Story, :component
        def function, do: nil
      end

      assert MyComponentStory.storybook_type() == :component
      assert MyComponentStory.variations() == []
    end

    test "attributes from component & story are merged" do
      defmodule Component do
        use Phoenix.Component
        attr(:label, :string, required: true, doc: "documentation", examples: ["foo", "bar"])
        attr(:type, :atom, required: true, doc: "overriden", values: [:foo, :bar])
        def my_component(_assigns), do: nil
      end

      defmodule ComponentStory do
        use PhoenixStorybook.Story, :component
        def function, do: &Component.my_component/1

        def attributes do
          [
            %Attr{id: :color, type: :atom, default: :gray, values: [:gray, :blue, :red]},
            %Attr{id: :type, type: :atom, doc: "documentation"}
          ]
        end
      end

      assert ComponentStory.merged_attributes() == [
               %Attr{
                 id: :label,
                 type: :string,
                 required: true,
                 default: nil,
                 doc: "documentation",
                 examples: ["foo", "bar"],
                 values: nil
               },
               %Attr{
                 id: :type,
                 type: :atom,
                 required: true,
                 default: nil,
                 doc: "documentation",
                 examples: nil,
                 values: [:foo, :bar]
               },
               %Attr{
                 id: :color,
                 type: :atom,
                 required: false,
                 default: :gray,
                 doc: nil,
                 examples: nil,
                 values: [:gray, :blue, :red]
               }
             ]
    end

    test "slots from component & story are merged" do
      defmodule SlotComponent do
        use Phoenix.Component
        slot(:foo, required: true)

        slot :nested, doc: "with nested attrs" do
          attr(:nested_attr, :string)
        end

        def slot_component(_assigns), do: nil
      end

      defmodule SlotComponentStory do
        use PhoenixStorybook.Story, :component
        def function, do: &SlotComponent.slot_component/1

        def slots do
          [
            %Slot{id: :foo, doc: "foo documentation"},
            %Slot{id: :bar}
          ]
        end
      end

      assert SlotComponentStory.merged_slots() == [
               %Slot{id: :foo, doc: "foo documentation", required: true},
               %Slot{id: :nested, doc: "with nested attrs", required: false},
               %Slot{id: :bar, doc: nil, required: false}
             ]
    end
  end

  describe "live_component story" do
    test "live_component story default behaviors" do
      defmodule MyLiveComponentStory do
        use PhoenixStorybook.Story, :live_component
        def component, do: nil
      end

      assert MyLiveComponentStory.storybook_type() == :live_component
      assert MyLiveComponentStory.variations() == []
    end

    test "attributes from component & story are merged" do
      defmodule LiveComponent do
        use Phoenix.LiveComponent
        attr(:label, :string, required: true, doc: "documentation", examples: ["foo", "bar"])
        attr(:type, :atom, required: true, doc: "overriden", values: [:foo, :bar])
        def render(_assigns), do: nil
      end

      defmodule LiveComponentStory do
        use PhoenixStorybook.Story, :live_component
        def component, do: LiveComponent

        def attributes do
          [
            %Attr{id: :color, type: :atom, default: :gray, values: [:gray, :blue, :red]},
            %Attr{id: :type, type: :atom, doc: "documentation"}
          ]
        end
      end

      assert LiveComponentStory.merged_attributes() == [
               %Attr{
                 id: :label,
                 type: :string,
                 required: true,
                 default: nil,
                 doc: "documentation",
                 examples: ["foo", "bar"],
                 values: nil
               },
               %Attr{
                 id: :type,
                 type: :atom,
                 required: true,
                 default: nil,
                 doc: "documentation",
                 examples: nil,
                 values: [:foo, :bar]
               },
               %Attr{
                 id: :color,
                 type: :atom,
                 required: false,
                 default: :gray,
                 doc: nil,
                 examples: nil,
                 values: [:gray, :blue, :red]
               }
             ]
    end

    test "slots from component & story are merged" do
      defmodule SlotLiveComponent do
        use Phoenix.LiveComponent
        slot(:foo, required: true)

        slot :nested, doc: "with nested attrs" do
          attr(:nested_attr, :string)
        end

        def render(_assigns), do: nil
      end

      defmodule SlotLiveComponentStory do
        use PhoenixStorybook.Story, :live_component
        def component, do: SlotLiveComponent

        def slots do
          [
            %Slot{id: :foo, doc: "foo documentation"},
            %Slot{id: :bar}
          ]
        end
      end

      assert SlotLiveComponentStory.merged_slots() == [
               %Slot{id: :foo, doc: "foo documentation", required: true},
               %Slot{id: :nested, doc: "with nested attrs", required: false},
               %Slot{id: :bar, doc: nil, required: false}
             ]
    end
  end

  describe "page story" do
    test "page story default behaviors" do
      defmodule MyPageStory do
        use PhoenixStorybook.Story, :page
      end

      assert MyPageStory.storybook_type() == :page
      assert MyPageStory.navigation() == []
      assert MyPageStory.render(%{}) == false
    end
  end
end
