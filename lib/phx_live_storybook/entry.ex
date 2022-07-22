defmodule PhxLiveStorybook.Entry do
  def component do
    quote do
      alias PhxLiveStorybook.Components.Variation

      def storybook_type, do: :component

      def public_name do
        call(:name, fn -> __MODULE__ |> Module.split() |> Enum.at(-1) end)
      end

      def public_component, do: call(:component)
      def public_function, do: call(:function)
      def public_description, do: call(:description, fn -> "" end)
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
