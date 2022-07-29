defmodule PhxLiveStorybook.Variation do
  @moduledoc """
  A variation is an example of how your component can be used.

  Each variation will be displayed in the storybook as a code
  snippet alongside with the component preview.

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
          slots: \"\"\"
          <:entry path="#" label="Account settings"/>
          <:entry path="#" label="Support"/>
          <:entry path="#" label="License"/>
          \"\"\"
        }
      ]
    end
  ```
  """

  @enforce_keys [:id, :attributes]
  defstruct [:id, :description, :attributes, :slots, :block]
end

defmodule PhxLiveStorybook.VariationGroup do
  @moduledoc """
  A variation group is a set of similar variations that will
  be rendered together in a single preview <pre> block.

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
  defstruct [:id, :description, :variations]
end
