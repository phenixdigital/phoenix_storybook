defmodule PhxLiveStorybook.Story do
  @moduledoc """
  A story designates any kind of content in your storybook. For now
  only following kinds of stories are supported: `component`, `:live_component`,
  and `:page`.

  In order to populate your storybook, just create _story_ scripts under your
  content path, and implement their required behaviour.

  Stories must be created as `.exs` files.

  ## Usage

  ### Component

  Implement your component as such.
  Confer to:
  - `PhxLiveStorybook.Variation` documentation for stories.
  - `PhxLiveStorybook.Attr` documentation for attributes.

  ```elixir
  # storybook/my_component.exs
  defmodule MyAppWeb.Storybook.MyComponent do
    use PhxLiveStorybook.Story, :component

    # required
    def function, do: &MyAppWeb.MyComponent.my_component/1

    def name, do: "Another name for my component"
    def description, do: "My component description"
    def icon, do: "fa fa-icon"

    def attributes, do: []
    def variations, do: []
  end
  ```

  ### Live Component

  Very similar to components, except that you need to define a `component/0` function
  instead of `function/0`.

  ```elixir
  # storybook/my_live_component.exs
  defmodule MyAppWeb.Storybook.MyLiveComponent do
    use PhxLiveStorybook.Story, :live_component

    # required
    def component, do: MyAppWeb.MyLiveComponent

    def name, do: "Another name for my component"
    def description, do: "My live component description"
    def icon, do: "fa fa-icon"

    def attributes, do: []
    def variations, do: []
  end
  ```

  ℹ️ Learn more on components in the [components guide](guides/components.md).

  ### Page

  A page is a fairly simple story that can be used to write whatever
  content you want. We use it to provide some UI guidelines.

  You should implement the render function and an optional navigation function,
  if you want a tab based sub-navigation. Current tab is passed as `:tab`
  in `render/1` assigns.

  ```elixir
  # storybook/my_page.exs
  defmodule MyAppWeb.Storybook.MyPage do
    use PhxLiveStorybook.Story, :page

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
      <div>Your HEEX template</div>
      \"\"\"
    end
  end

  ```
  """

  defmodule StoryBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback name() :: String.t()
    @callback description() :: String.t()
    @callback icon() :: String.t()
    @callback container() :: atom()
  end

  defmodule ComponentBehaviour do
    @moduledoc false

    @callback function() :: function()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback attributes() :: [PhxLiveStorybook.Attr.t()]
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
    @callback template() :: %Phoenix.LiveView.Rendered{}
  end

  defmodule LiveComponentBehaviour do
    @moduledoc false

    @callback component() :: atom()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback attributes() :: [PhxLiveStorybook.Attr.t()]
    @callback variations() :: [PhxLiveStorybook.Variation.t()]
    @callback template() :: %Phoenix.LiveView.Rendered{}
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
      @behaviour StoryBehaviour
      @behaviour unquote(component_behaviour(live?))

      alias PhxLiveStorybook.{Attr, Variation, VariationGroup}

      @impl StoryBehaviour
      def storybook_type, do: unquote(storybook_type(live?))

      @impl StoryBehaviour
      def name, do: unquote(module_name(module))

      @impl StoryBehaviour
      def description, do: nil

      @impl StoryBehaviour
      def icon, do: nil

      @impl StoryBehaviour
      def container, do: :div

      @impl unquote(component_behaviour(live?))
      def imports, do: []

      @impl unquote(component_behaviour(live?))
      def aliases, do: []

      @impl unquote(component_behaviour(live?))
      def attributes, do: []

      @impl unquote(component_behaviour(live?))
      def variations, do: []

      @impl unquote(component_behaviour(live?))
      def template, do: PhxLiveStorybook.TemplateHelpers.default_template()

      defoverridable name: 0,
                     description: 0,
                     icon: 0,
                     imports: 0,
                     aliases: 0,
                     container: 0,
                     variations: 0,
                     attributes: 0,
                     template: 0
    end
  end

  @doc false
  def page(module) do
    quote do
      import Phoenix.LiveView.Helpers

      @behaviour StoryBehaviour
      @behaviour PageBehaviour

      @impl StoryBehaviour
      def storybook_type, do: :page

      @impl StoryBehaviour
      def name, do: unquote(module_name(module))

      @impl StoryBehaviour
      def description, do: nil

      @impl StoryBehaviour
      def icon, do: nil

      @impl StoryBehaviour
      def container, do: :div

      @impl PageBehaviour
      def navigation, do: []

      def render(_assigns), do: false

      defoverridable name: 0, description: 0, icon: 0, navigation: 0, container: 0, render: 1
    end
  end

  @doc false
  def component_behaviour(_live = true), do: LiveComponentBehaviour
  def component_behaviour(_live = false), do: ComponentBehaviour

  @doc false
  def storybook_type(_live = true), do: :live_component
  def storybook_type(_live = false), do: :component

  @doc false
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
