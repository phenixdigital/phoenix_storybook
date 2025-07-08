defmodule PhoenixStorybook.Index do
  @moduledoc """
  An index is an optional file you can create in every folder of your storybook content tree to
  improve rendering of the storybook sidebar.

  The index files can be used:
    - to customize the folder itself: name, icon, index and opening status.
    - to customize folder direct children (only stories): name, icon and index.

  Sidebar entries are sorted alphabetically unless a numerical index is specified in the index file,
  either for the folder itself or for its entries.

  Indexes must be created as `index.exs` files.

  Read the [icons](guides/icons.md) guide for more information on custom icon usage.

  ## Usage

  ```elixir
  # storybook/_components.index.exs
  defmodule MyAppWeb.Storybook.Components do
    use PhoenixStorybook.Index

    def folder_name, do: "My Components"
    def folder_icon, do: {:fa, "icon"}
    def folder_open?, do: true
    def folder_index, do: 0

    def entry("a_component"), do: [name: "My Component", index: 1]
    def entry("other_component"), do: [name: "Another Component", icon: {:fa, "icon", :thin}, index: 0]
  end
  ```
  """

  defmodule IndexBehaviour do
    @moduledoc false
    alias PhoenixStorybook.Components.Icon

    @callback folder_name() :: nil | String.t()
    @callback folder_icon() :: nil | Icon.t()
    @callback folder_open?() :: boolean()
    @callback folder_index() :: integer()
    @callback entry(String.t()) :: keyword(String.t() | Icon.t())
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(_) do
    quote do
      @behaviour IndexBehaviour

      @on_definition {PhoenixStorybook.Stories.IndexValidator, :on_definition}

      @impl IndexBehaviour
      def folder_name, do: nil

      @impl IndexBehaviour
      def folder_icon, do: nil

      @impl IndexBehaviour
      def folder_open?, do: false

      @impl IndexBehaviour
      def folder_index, do: nil

      @impl IndexBehaviour
      def entry(_), do: []

      defoverridable folder_name: 0, folder_icon: 0, folder_open?: 0, folder_index: 0, entry: 1
    end
  end
end
