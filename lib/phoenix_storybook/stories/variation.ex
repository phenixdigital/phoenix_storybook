defmodule PhoenixStorybook.Stories.Variation do
  @moduledoc """
  A variation captures the rendered state of a UI component. Developers write multiple variations
  per component that describe all the “interesting” states a component can support.

  Each variation will be displayed in the storybook as a code snippet alongside with the
  component preview.

  Variations attributes type are checked against their matching attribute (if any) and will raise
  a compilation an error in case of mismatch.

  Advanced component & variation documentation is available in the
  [components guide](guides/components.md).

  ## Usage
  ```elixir
    def variations do
      [
        %Variation{
          id: :default,
          description: "Default dropdown",
          note: "This variation shows the most common use case.",
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

  @type t :: %__MODULE__{
          id: atom,
          description: String.t() | nil,
          note: String.t() | nil,
          let: atom | nil,
          slots: [String.t()],
          attributes: map,
          template: :unset | String.t() | nil | false
        }

  @enforce_keys [:id]
  defstruct [:id, :description, :note, :let, slots: [], attributes: %{}, template: :unset]
end

defmodule PhoenixStorybook.Stories.VariationGroup do
  @moduledoc """
  A variation group is a set of similar variations that will be rendered together in a single
  preview <pre> block.

  ## Usage
  ```elixir
    def variations do
      [
        %VariationGroup{
          id: :colors,
          description: "Different color buttons",
          note: "Note that every button has a different color.",
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

  alias PhoenixStorybook.Stories.Variation

  @type t :: %__MODULE__{
          id: atom,
          description: String.t() | nil,
          note: String.t() | nil,
          variations: [Variation.t()],
          template: :unset | String.t() | nil | false
        }

  @enforce_keys [:id, :variations]
  defstruct [:id, :description, :note, :variations, template: :unset]
end
