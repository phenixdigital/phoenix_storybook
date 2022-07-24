defmodule PhxLiveStorybook.Entry do
  @moduledoc """
  An entry designates any kind of content in your storybook. For now
  only two kinds of entries are supported: `component` and `:live_component`, but
  `:page` and `:example` will follow in later versions.

  In order to populate your storybook, just create _entry_ modules under your
  content path, and implement their required behavior.

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

  @doc false
  def live_component, do: component(live: true)

  @doc false
  def component(opts \\ [live: false]) do
    quote do
      alias PhxLiveStorybook.Variation

      def storybook_type, do: :component
      def live_component?, do: Keyword.get(unquote(opts), :live)

      def public_name do
        call(:name, fn ->
          __MODULE__
          |> Module.split()
          |> Enum.at(-1)
          |> Macro.underscore()
          |> String.split("_")
          |> Enum.map_join(" ", &String.capitalize/1)
        end)
      end

      def public_component, do: call(:component)
      def public_function, do: call(:function)
      def public_description, do: call(:description, fn -> "" end)
      def public_icon, do: call(:icon)
      def public_variations, do: call(:variations, fn -> [] end)

      defp call(fun, fallback \\ fn -> nil end, args \\ []) do
        if Kernel.function_exported?(__MODULE__, fun, length(args)) do
          apply(__MODULE__, fun, args)
        else
          apply(fallback, args)
        end
      end
    end
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
