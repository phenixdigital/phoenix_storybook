defmodule PhxLiveStorybook do
  alias PhxLiveStorybook.StorybookEntries

  defmacro __using__(opts) do
    [quotes(opts), StorybookEntries.quotes(opts)]
  end

  def quotes(opts) do
    quote do
      def config(key) do
        otp_app = Keyword.get(unquote(opts), :otp_app)
        otp_app
        |> Application.get_env(__MODULE__, [])
        |> Keyword.get(key)
      end
    end
  end
end
