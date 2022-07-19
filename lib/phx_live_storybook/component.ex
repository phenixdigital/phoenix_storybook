defmodule PhxLiveStorybook.Component do
  defmacro __using__(_) do
    quote do
      def public_name do
        call_unless_overidden(:name, fn ->
          __MODULE__ |> Module.split() |> Enum.at(-1)
        end)
      end

      defp call_unless_overidden(fun, args \\ [], fallback) do
        if Kernel.function_exported?(__MODULE__, fun, length(args)) do
          apply(__MODULE__, fun, args)
        else
          apply(fallback, args)
        end
      end
    end
  end
end
