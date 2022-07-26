defmodule PhxLiveStorybook.Router do
  @moduledoc """
  Provides LiveView routing for storybook.
  """

  @doc """
  Defines a PhxLiveStorybook route.

  It expects the `path` the storybook will be mounted at and a set
  of options.

  This will also generate a named helper called `live_dashboard_path/2`
  which you can use to link directly to the dashboard, such as:

  ```elixir
  <%= link "Storybook", to: live_storybook_path(conn, :home) %>
  ```

  Note you should only use `link/2` to link to the storybook (and not
  `live_redirect/live_link`, as it has to set its own session on first
  render.

  ## Options
    * `:otp_app` - _Required_ - OTP Name of your Phoenix application.
      It must match `:otp_app` of your backend module and settings.
    * `:backend_module` - _Required_ - Name of your backend module.
    * `:live_socket_path` - Configures the socket path. It must match
      the `socket "/live", Phoenix.LiveView.Socket` in your endpoint.

  ## Usage

  ```elixir
  # lib/my_app_web/router.ex
  use MyAppWeb, :router
  import PhxLiveStorybook.Router
  ...

  scope "/" do
    pipe_through :browser
    live_storybook "/storybook",
      otp_app: :my_app,
      backend_module: MyAppWeb.Storybook
  end
  ```
  """
  defmacro live_storybook(path, opts \\ []) do
    opts = Keyword.put(opts, :application_router, __CALLER__.module)

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
  def __options__(opts) do
    live_socket_path = Keyword.get(opts, :live_socket_path, "/live")

    otp_app =
      Keyword.get_lazy(opts, :otp_app, fn -> raise "Missing mandatory :otp_app option." end)

    backend_module =
      Keyword.get_lazy(opts, :backend_module, fn ->
        raise "Missing mandatory :backend_module option."
      end)

    {
      :live_storybook,
      [
        root_layout: {PhxLiveStorybook.LayoutView, :root},
        session: %{"backend_module" => backend_module, "otp_app" => otp_app}
      ],
      [
        private: %{
          live_socket_path: live_socket_path,
          otp_app: otp_app,
          backend_module: backend_module,
          application_router: Keyword.get(opts, :application_router)
        },
        as: :live_storybook
      ]
    }
  end
end
