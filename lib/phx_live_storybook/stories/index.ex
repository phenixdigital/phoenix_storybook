defmodule PhxLiveStorybook.Index do
  @moduledoc """
  An index is an optional file you can create in every folder of your storybook content tree to
  improve rendering of the storybook sidebar.

  The index files can be used:
    - to customize the folder itself: name, icon and opening status.
    - to customize folder direct children (only stories): name and icon.

  Indexes must be created as `index.exs` files.

  Read the [icons](guides/icons.md) guide for more information on custom icon usage.

  ## Usage

  ```elixir
  # storybook/_components.index.exs
  defmodule MyAppWeb.Storybook.Components do
    use PhxLiveStorybook.Index

    def folder_name, do: "My Components"
    def folder_icon, do: {:fa, "icon"}
    def folder_open?, do: true

    def entry("a_component"), do: [name: "My Component"]
    def entry("other_component"), do: [name: "Another Component", icon: {:fa, "icon", :thin}]
  end
  ```
  """

  defmodule IndexBehaviour do
    @moduledoc false

    @type icon_provider :: :fa | :hero
    @type icon ::
            {icon_provider(), String.t()}
            | {icon_provider(), String.t(), atom}
            | {icon_provider(), String.t(), atom, String.t()}

    @callback folder_name() :: nil | String.t()
    @callback folder_icon() :: nil | icon()
    @callback folder_open?() :: boolean()
    @callback entry(String.t()) :: [key: String.t() | icon()]
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(_) do
    quote do
      @behaviour IndexBehaviour

      @on_definition {PhxLiveStorybook.Stories.IndexValidator, :on_definition}

      @impl IndexBehaviour
      def folder_name, do: nil

      @impl IndexBehaviour
      def folder_icon, do: nil

      @impl IndexBehaviour
      def folder_open?, do: false

      @impl IndexBehaviour
      def entry(_), do: []

      defoverridable folder_name: 0, folder_icon: 0, folder_open?: 0, entry: 1
    end
  end
end
