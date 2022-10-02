defmodule Storybook.Components.Icon do
  # See https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.Story.html for full story
  # documentation.
  # Read https://hexdocs.pm/phx_live_storybook/components.html for more advanced options.

  use PhxLiveStorybook.Story, :component

  def function, do: &PhxLiveStorybook.Components.Icon.hero_icon/1

  # A variation captures the rendered state of a UI component. Developers write multiple variations
  # per component that describe all the “interesting” states a component can support.
  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          name: "calendar",
          class: "lsb-w-8 lsb-h-8"
        }
      },
      %Variation{
        id: :icon_variation,
        attributes: %{
          name: "bookmark",
          class: "lsb-w-8 lsb-h-8 lsb-text-red-500"
        }
      },
      %VariationGroup{
        id: :group,
        variations: [
          %Variation{
            id: :item_1,
            attributes: %{name: "cake", class: "lsb-w-8 lsb-h-8"}
          },
          %Variation{
            id: :item_2,
            attributes: %{name: "cake", class: "lsb-w-16 lsb-h-16"}
          }
        ]
      }
    ]
  end
end
