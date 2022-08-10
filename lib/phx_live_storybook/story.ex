defmodule PhxLiveStorybook.Story do
  @moduledoc """
  A story captures the rendered state of a UI component. Developers write
  multiple stories per component that describe all the “interesting” states
  a component can support.

  Each story will be displayed in the storybook as a code
  snippet alongside with the component preview.

  ## Usage
  ```elixir
    def stories do
      [
        %Story{
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

  @enforce_keys [:id, :attributes]
  defstruct [:id, :description, :attributes, :slots, :block]
end

defmodule PhxLiveStorybook.StoryGroup do
  @moduledoc """
  A story group is a set of similar stories that will
  be rendered together in a single preview <pre> block.

  ## Usage
  ```elixir
    def stories do
      [
        %StoryGroup{
          id: colors,
          description: "Different color buttons",
          stories: [
            %Story{
              id: :blue_button,
              attributes: %{label: "A button", color: :blue }
            },
            %Story{
              id: :red_button,
              attributes: %{label: "A button", color: :red }
            },
            %Story{
              id: :green_button,
              attributes: %{label: "A button", color: :green }
            }
          ]
        }
      ]
    end
  ```
  """

  @enforce_keys [:id, :stories]
  defstruct [:id, :description, :stories]
end
