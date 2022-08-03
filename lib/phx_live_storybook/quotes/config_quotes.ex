defmodule PhxLiveStorybook.Quotes.ConfigQuotes do
  @moduledoc false

  # This quote provides config access helper
  @doc false
  def config_quotes(backend_module, otp_app) do
    quote do
      @behaviour PhxLiveStorybook.BackendBehaviour

      @impl PhxLiveStorybook.BackendBehaviour
      def config(key, default \\ nil) do
        unquote(otp_app)
        |> Application.get_env(unquote(backend_module), [])
        |> Keyword.get(key, default)
      end
    end
  end
end
