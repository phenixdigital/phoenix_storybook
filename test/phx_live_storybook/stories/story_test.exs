defmodule PhxLiveStorybook.StoryTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.Stories.Attr

  describe "component story" do
    test "component story default behaviors" do
      defmodule MyComponentStory do
        use PhxLiveStorybook.Story, :component
        def function, do: nil
      end

      assert MyComponentStory.storybook_type() == :component
      assert MyComponentStory.description() == nil
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
        use PhxLiveStorybook.Story, :component
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
  end

  describe "live_component story" do
    test "live_component story default behaviors" do
      defmodule MyLiveComponentStory do
        use PhxLiveStorybook.Story, :live_component
        def component, do: nil
      end

      assert MyLiveComponentStory.storybook_type() == :live_component
      assert MyLiveComponentStory.description() == nil
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
        use PhxLiveStorybook.Story, :live_component
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
  end

  describe "page story" do
    test "page story default behaviors" do
      defmodule MyPageStory do
        use PhxLiveStorybook.Story, :page
      end

      assert MyPageStory.storybook_type() == :page
      assert MyPageStory.description() == nil
      assert MyPageStory.navigation() == []
      assert MyPageStory.render(%{}) == false
    end
  end
end
