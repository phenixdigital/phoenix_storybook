defmodule PhxLiveStorybook.Story do
  @moduledoc """
  A story designates any kind of content in your storybook. For now only following kinds of stories
  are supported: `component`, `:live_component`, and `:page`.

  In order to populate your storybook, just create _story_ scripts under your content path, and
  implement their required behaviour.

  Stories must be created as `story.exs` files.

  In dev environment, stories are lazily compiled when reached from the UI.

  ## Usage

  ### Component

  Implement your component as such.
  Confer to:
  - `PhxLiveStorybook.Variation` documentation for variations.
  - `PhxLiveStorybook.Attr` documentation for attributes.

  ```elixir
  # storybook/my_component.exs
  defmodule MyAppWeb.Storybook.MyComponent do
    use PhxLiveStorybook.Story, :component

    # required
    def function, do: &MyAppWeb.MyComponent.my_component/1
    def description, do: "My component description"

    def attributes, do: []
    def slots, do: []
    def variations, do: []
  end
  ```

  ### Live Component

  Very similar to components, except that you need to define a `component/0` function instead of
  `function/0`.

  ```elixir
  # storybook/my_live_component.exs
  defmodule MyAppWeb.Storybook.MyLiveComponent do
    use PhxLiveStorybook.Story, :live_component

    # required
    def component, do: MyAppWeb.MyLiveComponent
    def description, do: "My live component description"
    def attributes, do: []
    def slots, do: []
    def variations, do: []
  end
  ```

  ℹ️ Learn more on components in the [components guide](guides/components.md).

  ### Page

  A page is a fairly simple story that can be used to write whatever content you want. We use it to
  provide some UI guidelines.

  You should implement the render function and an optional navigation function, if you want a tab
  based sub-navigation. Current tab is passed as `:tab` in `render/1` assigns.

  ```elixir
  # storybook/my_page.exs
  defmodule MyAppWeb.Storybook.MyPage do
    use PhxLiveStorybook.Story, :page

    def description, do: "My page description"

    def navigation do
      [
        {:tab_one, "Tab One", "tab-icon"},
        {:tab_two, "Tab Two", "tab-icon"}
      ]
    end

    def render(assigns) do
      ~H"<div>Your HEEX template</div>"
    end
  end
  ```
  """

  alias PhxLiveStorybook.Stories.{Attr, Slot, Variation, VariationGroup}
  alias PhxLiveStorybook.Stories.StoryComponentSource

  defmodule StoryBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback description() :: String.t()
  end

  defmodule ComponentBehaviour do
    @moduledoc false

    @callback function() :: function()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback container() :: atom()
    @callback attributes() :: [Attr.t()]
    @callback slots() :: [Slot.t()]
    @callback variations() :: [Variation.t() | VariationGroup.t()]
    @callback template() :: String.t()
  end

  defmodule LiveComponentBehaviour do
    @moduledoc false

    @callback component() :: atom()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback container() :: atom()
    @callback attributes() :: [Attr.t()]
    @callback slots() :: [Slot.t()]
    @callback variations() :: [Variation.t() | VariationGroup.t()]
    @callback template() :: String.t()
  end

  defmodule PageBehaviour do
    @moduledoc false

    @callback navigation() :: [{atom(), String.t(), String.t()}]
    @callback render(map()) :: %Phoenix.LiveView.Rendered{}
  end

  @doc false
  def live_component, do: component_quote(true)

  @doc false
  def component, do: component_quote(false)

  defp component_quote(live?) do
    quote do
      @behaviour StoryBehaviour
      @behaviour unquote(component_behaviour(live?))
      @before_compile StoryComponentSource

      alias PhxLiveStorybook.Stories.{Attr, Slot, Variation, VariationGroup}

      @impl StoryBehaviour
      def storybook_type, do: unquote(storybook_type(live?))

      @impl StoryBehaviour
      def description, do: nil

      @impl unquote(component_behaviour(live?))
      def container, do: :div

      @impl unquote(component_behaviour(live?))
      def imports, do: []

      @impl unquote(component_behaviour(live?))
      def aliases, do: []

      @impl unquote(component_behaviour(live?))
      def attributes, do: []

      @impl unquote(component_behaviour(live?))
      def slots, do: []

      @impl unquote(component_behaviour(live?))
      def variations, do: []

      @impl unquote(component_behaviour(live?))
      def template, do: PhxLiveStorybook.TemplateHelpers.default_template()

      if unquote(live?) do
        def merged_attributes, do: Attr.merge_attributes(component(), attributes())
        def merged_slots, do: Slot.merge_slots(component(), slots())
      else
        def merged_attributes, do: Attr.merge_attributes(function(), attributes())
        def merged_slots, do: Slot.merge_slots(function(), slots())
      end

      defoverridable description: 0,
                     imports: 0,
                     aliases: 0,
                     container: 0,
                     attributes: 0,
                     slots: 0,
                     variations: 0,
                     template: 0
    end
  end

  @doc false
  def page do
    quote do
      import Phoenix.Component

      @behaviour StoryBehaviour
      @behaviour PageBehaviour

      @before_compile StoryComponentSource

      @impl StoryBehaviour
      def storybook_type, do: :page

      @impl StoryBehaviour
      def description, do: nil

      @impl PageBehaviour
      def navigation, do: []

      @impl PageBehaviour
      def render(_assigns), do: false

      defoverridable description: 0, navigation: 0, render: 1
    end
  end

  @doc false
  def component_behaviour(_live = true), do: LiveComponentBehaviour
  def component_behaviour(_live = false), do: ComponentBehaviour

  @doc false
  def storybook_type(_live = true), do: :live_component
  def storybook_type(_live = false), do: :component

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
