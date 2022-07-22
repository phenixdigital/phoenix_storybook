defmodule PhxLiveStorybook.Router do
  @moduledoc """
  Provides LiveView routing for storybook.
  """

  defmacro live_storybook(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        {session_name, session_opts, route_opts} = PhxLiveStorybook.Router.__options__(opts)
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        live_session session_name, session_opts do
          live("/", PhxLiveStorybook.EntryLive, :home, route_opts)
          live("/*entry", PhxLiveStorybook.EntryLive, :entry, route_opts)
        end
      end
    end
  end

  @doc false
  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")
    otp_app = Keyword.get_lazy(options, :otp_app, fn -> raise "Missing mandatory :otp_app option." end)
    backend_module = Keyword.get_lazy(options, :backend_module, fn -> raise "Missing mandatory :backend_module option." end)

    {
      :live_storybook,
      [
        root_layout: {PhxLiveStorybook.LayoutView, :storybook}
      ],
      [
        private: %{live_socket_path: live_socket_path, otp_app: otp_app, backend_module: backend_module},
        as: :live_storybook
      ]
    }
  end
end
