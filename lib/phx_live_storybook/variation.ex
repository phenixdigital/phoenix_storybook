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
