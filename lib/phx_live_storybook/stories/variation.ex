defmodule PhxLiveStorybook.Stories.Variation do
  @moduledoc """
  A varaiation captures the rendered state of a UI component. Developers write multiple variations
  per component that describe all the “interesting” states a component can support.

  Each variation will be displayed in the storybook as a code snippet alongside with the
  component preview.

  ## Usage
  ```elixir
    def variations do
      [
        %Variation{
          id: :default,
          description: "Default dropdown",
          attributes: %{
            label: "A dropdown",
          },
          slots: [
            ~s|<:entry path="#" label="Account settings"/>|,
            ~s|<:entry path="#" label="Support"/>|,
            ~s|<:entry path="#" label="License"/>|
          ]
        }
      ]
    end
  ```
  """

  @enforce_keys [:id]
  defstruct [:id, :description, :let, slots: [], attributes: %{}, template: :unset]
end

defmodule PhxLiveStorybook.Stories.VariationGroup do
  @moduledoc """
  A variation group is a set of similar variations that will be rendered together in a single
  preview <pre> block.

  ## Usage
  ```elixir
    def variations do
      [
        %VariationGroup{
          id: colors,
          description: "Different color buttons",
          variations: [
            %Variation{
              id: :blue_button,
              attributes: %{label: "A button", color: :blue }
            },
            %Variation{
              id: :red_button,
              attributes: %{label: "A button", color: :red }
            },
            %Variation{
              id: :green_button,
              attributes: %{label: "A button", color: :green }
            }
          ]
        }
      ]
    end
  ```
  """

  @enforce_keys [:id, :variations]
  defstruct [:id, :description, :variations, template: :unset]
end
