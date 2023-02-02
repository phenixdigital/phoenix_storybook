defmodule Storybook.Components.Icon do
  # See https://hexdocs.pm/phoenix_storybook/PhoenixStorybook.Story.html for full story
  # documentation.
  # Read https://hexdocs.pm/phoenix_storybook/components.html for more advanced options.

  use PhoenixStorybook.Story, :component

  def function, do: &PhoenixStorybook.Components.Icon.hero_icon/1

  # A variation captures the rendered state of a UI component. Developers write multiple variations
  # per component that describe all the “interesting” states a component can support.
  def variations do
    if Code.ensure_loaded?(Heroicons) do
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
    else
      []
    end
  end
end
