defmodule Storybook.Components.MyComponent do
  # See https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.Story.html for full story
  # documentation.
  # Read https://hexdocs.pm/phx_live_storybook/components.html for more advanced options.

  use PhxLiveStorybook.Story, :component

  # This is a dummy fonction that you should replace with your own component function:
  # def function, do: &MyButton.my_button/1
  def function, do: fn assigns -> ~H"<span><%=@text%></span>" end

  # A variation captures the rendered state of a UI component. Developers write multiple variations
  # per component that describe all the “interesting” states a component can support.
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          text: "Hello World"
        }
      },
      %Variation{
        id: :text_variation,
        attributes: %{
          text: "A text variation"
        }
      },
      %VariationGroup{
        id: :group,
        variations: [
          %Variation{id: :item_1, attributes: %{text: "item 1"}},
          %Variation{id: :item_2, attributes: %{text: "item 2"}},
        ]
      }
    ]
  end
end
