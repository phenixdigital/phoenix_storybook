defmodule PhoenixStorybook.Story do
  @moduledoc """
  A story designates any kind of content in your storybook. For now only following kinds of stories
  are supported `:component`, `:live_component`, and `:page`.

  In order to populate your storybook, just create _story_ scripts under your content path, and
  implement their required behaviour.

  Stories must be created as `story.exs` files.

  In dev environment, stories are lazily compiled when reached from the UI.

  ## Usage

  ### Component

  Implement your component as such.
  Confer to:
  - `PhoenixStorybook.Variation` documentation for variations.
  - `PhoenixStorybook.Attr` documentation for attributes.

  ```elixir
  # storybook/my_component.exs
  defmodule MyAppWeb.Storybook.MyComponent do
    use PhoenixStorybook.Story, :component

    # required
    def function, do: &MyAppWeb.MyComponent.my_component/1

    # By default (`:module` value), it will render the full component's mode source code.
    # - when set on `:function`, it will render only function's source code
    # - when set on `false`, the source tab will be unavailable
    def render_source, do: :function

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
    use PhoenixStorybook.Story, :live_component

    # required
    def component, do: MyAppWeb.MyLiveComponent

    def attributes, do: []
    def slots, do: []
    def variations, do: []
  end
  ```

  You can also define an optional `handle_info/2` in your live component story. It will be called
  by the storybook LiveView when your component sends messages to its parent (useful for `send_update/2`).

  ℹ️ Learn more on components in the [components guide](guides/components.md).

  ### Page

  A page is a fairly simple story that can be used to write whatever content you want. We use it to
  provide some UI guidelines.

  You should implement the render function and an optional navigation function, if you want a tab
  based sub-navigation. Current tab is passed as `:tab` in `render/1` assigns.

  ```elixir
  # storybook/my_page.exs
  defmodule MyAppWeb.Storybook.MyPage do
    use PhoenixStorybook.Story, :page

    def doc, do: "My page description"

    def navigation do
      [
        {:tab_one, "Tab One", {:fa, "book"}},
        {:tab_two, "Tab Two", {:fa, "cake", :solid}}
      ]
    end

    def render(assigns) do
      ~H"<div>Your HEEX template</div>"
    end
  end
  ```

  ### Example

  An example is a real-world UI showcasing how your components can be used and mixed in complex UI
  interfaces.

  Examples are rendered as a child LiveView, so you can implement `mount/3`, `render/1` or any
  `handle_event/3` callback. Unfortunately `handle_params/3` cannot be defined in a child LiveView.

  By default, your example story's source code will be shown in a dedicated tab. But you can show
  additional files source code by implementing the `extra_sources/0` function which should return a
  list of relative paths to your example related files.

  ```elixir
  # storybook/my_example.story.exs
  defmodule MyAppWeb.Storybook.MyPage do
    use PhoenixStorybook.Story, :example

    def doc, do: "My page description"

    def extra_sources do
      [
        "./template.html.heex",
        "./my_page_html.ex"
      ]
    end

    def mount(_, _, socket), do: {:ok, socket}

    def render(assigns) do
      ~H"<div>Your HEEX template</div>"
    end
  end
  ```
  """

  alias PhoenixStorybook.Components.Icon
  alias PhoenixStorybook.Stories.{Attr, Slot, Variation, VariationGroup}
  alias PhoenixStorybook.Stories.StorySource

  defmodule StoryBehaviour do
    @moduledoc false

    @callback storybook_type() :: atom()
    @callback doc() :: String.t() | [String.t()] | nil
  end

  defmodule ComponentBehaviour do
    @moduledoc """
    Behaviour implemented by any component story
    """

    @callback function() :: function()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback container() :: atom() | {atom(), [{atom(), String.t()}]}
    @callback attributes() :: [Attr.t()]
    @callback slots() :: [Slot.t()]
    @callback variations() :: [Variation.t() | VariationGroup.t()]
    @callback template() :: String.t()
    @callback layout() :: atom()
    @callback render_source() :: atom()
    @callback unstripped_doc() :: String.t() | [String.t()] | nil
  end

  defmodule LiveComponentBehaviour do
    @moduledoc """
    Behaviour implemented by any live component story
    """

    @callback component() :: atom()
    @callback imports() :: [{atom(), [{atom(), integer()}]}]
    @callback aliases() :: [atom()]
    @callback container() :: atom()
    @callback attributes() :: [Attr.t()]
    @callback slots() :: [Slot.t()]
    @callback variations() :: [Variation.t() | VariationGroup.t()]
    @callback template() :: String.t()
    @callback layout() :: atom()
    @callback render_source() :: atom()
    @callback handle_info(term(), Phoenix.LiveView.Socket.t()) ::
                {:noreply, Phoenix.LiveView.Socket.t()}
    @optional_callbacks handle_info: 2
  end

  defmodule PageBehaviour do
    @moduledoc """
    Behaviour implemented by any page story
    """

    @callback navigation() :: [{atom(), String.t(), Icon.t()} | {atom(), String.t()}]
    @callback render(map()) :: %Phoenix.LiveView.Rendered{}
  end

  defmodule ExampleBehaviour do
    @moduledoc """
    Behaviour implemented by any example story
    """

    @callback extra_sources() :: [String.t()]
  end

  @doc false
  def live_component, do: component_quote(true)

  @doc false
  def component, do: component_quote(false)

  defp component_quote(live?) do
    quote do
      @behaviour StoryBehaviour
      @behaviour unquote(component_behaviour(live?))
      @before_compile StorySource

      alias Phoenix.LiveView.JS
      alias PhoenixStorybook.Stories.{Attr, Doc, Slot, Variation, VariationGroup}

      @impl StoryBehaviour
      def storybook_type, do: unquote(storybook_type(live?))

      @impl StoryBehaviour
      def doc do
        Doc.fetch_doc_as_html(__MODULE__, true)
      end

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
      def template, do: PhoenixStorybook.TemplateHelpers.default_template()

      @impl unquote(component_behaviour(live?))
      def layout, do: :two_columns

      @impl unquote(component_behaviour(live?))
      def render_source, do: :module

      if unquote(live?) do
        def merged_attributes, do: Attr.merge_attributes(component(), attributes())
        def merged_slots, do: Slot.merge_slots(component(), slots())
      else
        def merged_attributes, do: Attr.merge_attributes(function(), attributes())
        def merged_slots, do: Slot.merge_slots(function(), slots())

        @impl ComponentBehaviour
        def unstripped_doc do
          Doc.fetch_doc_as_html(__MODULE__, false)
        end
      end

      defoverridable imports: 0,
                     aliases: 0,
                     container: 0,
                     attributes: 0,
                     slots: 0,
                     variations: 0,
                     template: 0,
                     layout: 0,
                     render_source: 0
    end
  end

  @doc false
  def page do
    quote do
      import Phoenix.Component

      @behaviour StoryBehaviour
      @behaviour PageBehaviour
      @before_compile StorySource

      @impl StoryBehaviour
      def storybook_type, do: :page

      @impl StoryBehaviour
      def doc, do: nil

      @impl PageBehaviour
      def navigation, do: []

      @impl PageBehaviour
      def render(_assigns), do: false

      defoverridable doc: 0, navigation: 0, render: 1
    end
  end

  @doc false
  def example do
    quote do
      use Phoenix.LiveView

      @behaviour StoryBehaviour
      @behaviour ExampleBehaviour
      @before_compile StorySource

      @impl StoryBehaviour
      def storybook_type, do: :example

      @impl StoryBehaviour
      def doc, do: nil

      @impl ExampleBehaviour
      def extra_sources, do: []

      defoverridable doc: 0, extra_sources: 0
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
