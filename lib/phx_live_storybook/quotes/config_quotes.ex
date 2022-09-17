defmodule PhxLiveStorybook.Quotes.ConfigQuotes do
  @moduledoc false

  # This quote provides config access helper
  @doc false
  def config_quotes(opts) do
    quote do
      @behaviour PhxLiveStorybook.BackendBehaviour

      @impl PhxLiveStorybook.BackendBehaviour
      def config(key, default \\ nil) do
        Keyword.get(unquote(opts), key, default)
      end
    end
  end
end
