defmodule PhxLiveStorybook.Index do
  defmodule IndexBehaviour do
    @moduledoc false

    @callback folder_name() :: String.t()
    @callback folder_icon() :: String.t()
    @callback entry(String.t()) :: [{atom(), String.t()}]
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(_) do
    quote do
      @behaviour IndexBehaviour

      @impl IndexBehaviour
      def folder_name, do: nil

      @impl IndexBehaviour
      def folder_icon, do: nil

      @impl IndexBehaviour
      def entry(_), do: []

      defoverridable folder_name: 0, folder_icon: 0, entry: 1
    end
  end
end
