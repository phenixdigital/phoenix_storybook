defmodule PhxLiveStorybook do
  alias PhxLiveStorybook.Entries

  defmacro __using__(opts) do
    [quotes(opts), Entries.quotes(opts)]
  end

  def quotes(opts) do
    quote do
      def config(key, default \\ nil) do
        otp_app = Keyword.get(unquote(opts), :otp_app)

        otp_app
        |> Application.get_env(__MODULE__, [])
        |> Keyword.get(key, default)
      end
    end
  end
end
