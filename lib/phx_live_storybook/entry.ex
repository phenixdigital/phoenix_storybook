defmodule PhxLiveStorybook.Entry do
  @moduledoc """
  An entry designates any kind of content in your storybook. For now
  only following kinds of entries are supported: `component`, `:live_component`,
  and `:page`.

  In order to populate your storybook, just create _entry_ modules under your
  content path, and implement their required behaviour.

  ## Usage

  ### Component

  Implement your component as such.
  Confer to `PhxLiveStorybook.Variation` documentation for variations.

  ```elixir
  defmodule MyAppWeb.Storybook.MyComponent do
    use PhxLiveStorybook.Entry, :component

    # required
    def component, do: MyAppWeb.MyComponent

    # required
    def function, do: &MyAppWeb.MyComponent.my_component/1

    def name, do: "Another name for my component"
    def description, do: "My component description"
    def icon, do: "fa fa-icon"
    def variations, do: []
  end
  ```

  ### Live Component

  Very similar components, excepted the `function/0` callback no longer required.

  ```elixir
  defmodule MyAppWeb.Storybook.MyLiveComponent do
    use PhxLiveStorybook.Entry, :live_component

    # required
    def component, do: MyAppWeb.MyLiveComponent

    def name, do: "Another name for my component"
    def description, do: "My live component description"
    def icon, do: "fa fa-icon"
    def variations, do: []
  end
  ```

  ### Page

  ```elixir
  defmodule MyAppWeb.Storybook.MyPage do
    use PhxLiveStorybook.Entry, :page

    def name, do: "Another name for my page"
    def description, do: "My page description"
    def icon, do: "fa fa-icon"

    def navigation do
      [
        {:tab_id, "Tab Name", "tab-icon"},
        {:tab_id, "Tab Name", "tab-icon"}
      ]
    end

    def render(assigns) do
      ~H\"\"\"
      Your HEEX template
      \"\"\"
    end
  end

  ```
  """

  defmodule EntryBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback name() :: String.t()
    @callback description() :: String.t()
    @callback icon() :: String.t()
  end

  defmodule ComponentBehaviour do
    @moduledoc false

    @callback component() :: atom()
    @callback function() :: function()
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
  end

  defmodule LiveComponentBehaviour do
    @moduledoc false

    @callback component() :: atom()
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
  end

  defmodule PageBehaviour do
    @moduledoc false

    @callback navigation() :: [{atom(), String.t(), String.t()}]
  end

  @doc false
  def live_component(module), do: component_quote(module, true)

  @doc false
  def component(module), do: component_quote(module, false)

  defp component_quote(module, live?) do
    quote do
      @behaviour EntryBehaviour
      @behaviour unquote(component_behaviour(live?))

      alias PhxLiveStorybook.Variation

      @impl EntryBehaviour
      def storybook_type, do: unquote(storybook_type(live?))

      @impl EntryBehaviour
      def name, do: unquote(module_name(module))

      @impl EntryBehaviour
      def description, do: ""

      @impl EntryBehaviour
      def icon, do: nil

      @impl unquote(component_behaviour(live?))
      def variations, do: []

      defoverridable name: 0, description: 0, icon: 0, variations: 0
    end
  end

  def page(module) do
    quote do
      use Phoenix.LiveComponent
      import Phoenix.LiveView.Helpers

      @behaviour EntryBehaviour
      @behaviour PageBehaviour

      @impl EntryBehaviour
      def storybook_type, do: :page

      @impl EntryBehaviour
      def name, do: unquote(module_name(module))

      @impl EntryBehaviour
      def description, do: ""

      @impl EntryBehaviour
      def icon, do: nil

      @impl PageBehaviour
      def navigation, do: []

      @impl Phoenix.LiveComponent
      def render(_assigns), do: false

      defoverridable name: 0, description: 0, icon: 0, navigation: 0, render: 1
    end
  end

  def component_behaviour(_live = true), do: LiveComponentBehaviour
  def component_behaviour(_live = false), do: ComponentBehaviour

  def storybook_type(_live = true), do: :live_component
  def storybook_type(_live = false), do: :component

  def module_name(module) do
    module
    |> Module.split()
    |> Enum.at(-1)
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [__CALLER__.module])
  end
end
