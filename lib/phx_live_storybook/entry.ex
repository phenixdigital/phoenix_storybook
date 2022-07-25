defmodule PhxLiveStorybook.Entry do
  @moduledoc """
  An entry designates any kind of content in your storybook. For now
  only two kinds of entries are supported: `component` and `:live_component`, but
  `:page` and `:example` will follow in later versions.

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

    def description, do: "My component description"
    def icon, do: "fa fa-icon"

    # required
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

    def description, do: "My live component description"
    def icon, do: "fa fa-icon"

    # required
    def variations, do: []
  end
  ```
  """

  defmodule ComponentBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback name() :: String.t()
    @callback component() :: atom()
    @callback function() :: function()
    @callback description() :: String.t()
    @callback icon() :: String.t()
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
  end

  defmodule LiveComponentBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback name() :: String.t()
    @callback component() :: atom()
    @callback description() :: String.t()
    @callback icon() :: String.t()
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
  end

  @doc false
  def live_component(module), do: component_quote(module, true)

  @doc false
  def component(module), do: component_quote(module, false)

  defp component_quote(module, live?) do
    quote do
      @behaviour unquote(component_behaviour(live?))

      alias PhxLiveStorybook.Variation

      @impl true
      def storybook_type, do: unquote(storybook_type(live?))

      @impl true
      def name, do: unquote(module_name(module))

      @impl true
      def description, do: ""

      @impl true
      def icon, do: nil

      @impl true
      def variations, do: []

      defoverridable name: 0, description: 0, icon: 0, variations: 0
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
