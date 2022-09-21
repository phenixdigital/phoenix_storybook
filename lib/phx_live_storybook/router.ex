defmodule PhxLiveStorybook.Router do
  @moduledoc """
  Provides LiveView routing for storybook.
  """

  @doc """
  Defines a PhxLiveStorybook route.

  It expects the `path` the storybook will be mounted at and a set
  of options.

  This will also generate a named helper called `live_storybook_path/2`
  which you can use to link directly to the storybook, such as:

  ```elixir
  <%= link "Storybook", to: live_storybook_path(conn, :root) %>
  ```

  Note that you should only use `link/2` to link to the storybook (and not
  `live_redirect/live_link`), as it has to set its own session on first
  rendering.

  ## Options
    * `:backend_module` - _Required_ - Name of your backend module.
    * `:live_socket_path` - Configures the socket path. It must match
      the `socket "/live", Phoenix.LiveView.Socket` in your endpoint.
    * `:assets_path` - Configures the assets path. It must match
      the `storybook_assets` in your router.

  ## Usage

  ```elixir
  # lib/my_app_web/router.ex
  use MyAppWeb, :router
  import PhxLiveStorybook.Router
  ...

  scope "/" do
    pipe_through :browser
    live_storybook "/storybook", backend_module: MyAppWeb.Storybook
  end
  ```
  """
  defmacro live_storybook(path, opts) do
    opts = Keyword.put(opts, :application_router, __CALLER__.module)

    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        pipeline :storybook_browser do
          plug(:accepts, ["html"])
          plug(:fetch_session)
          plug(:protect_from_forgery)
        end

        scope path: "/" do
          pipe_through(:storybook_browser)

          {session_name, session_opts, route_opts} =
            PhxLiveStorybook.Router.__options__(opts, :live_storybook_iframe, :root_iframe)

          live_session session_name, session_opts do
            live(
              "/iframe/*story",
              PhxLiveStorybook.Story.ComponentIframeLive,
              :story_iframe,
              route_opts
            )
          end

          {session_name, session_opts, route_opts} =
            PhxLiveStorybook.Router.__options__(opts, :live_storybook, :root)

          live_session session_name, session_opts do
            live("/", PhxLiveStorybook.StoryLive, :root, route_opts)
            live("/*story", PhxLiveStorybook.StoryLive, :story, route_opts)
          end
        end
      end
    end
  end

  @default_assets_path "/storybook/assets"

  @doc false
  def __options__(opts, session_name, root_layout) do
    live_socket_path = Keyword.get(opts, :live_socket_path, "/live")
    assets_path = Keyword.get(opts, :assets_path, @default_assets_path)

    backend_module =
      Keyword.get_lazy(opts, :backend_module, fn ->
        raise "Missing mandatory :backend_module option."
      end)

    {
      session_name,
      [
        root_layout: {PhxLiveStorybook.LayoutView, root_layout},
        session: %{
          "backend_module" => backend_module,
          "assets_path" => assets_path
        }
      ],
      [
        private: %{
          live_socket_path: live_socket_path,
          backend_module: backend_module,
          application_router: Keyword.get(opts, :application_router),
          assets_path: assets_path
        },
        as: :live_storybook
      ]
    }
  end

  @gzip_assets Application.compile_env(:phx_live_storybook, :gzip_assets, false)

  @doc """
  Defines routes for PhxLiveStorybook static assets.

  Static assets should not be CSRF protected. So they need to be mounted in your
  router in a different pipeline than storybook's.

  It can take the `path` the storybook assets will be mounted at.
  Default path is `"/storybook/assets"`.

  ## Usage

  ```elixir
  # lib/my_app_web/router.ex
  use MyAppWeb, :router
  import PhxLiveStorybook.Router
  ...

  scope "/" do
    storybook_assets()
  end
  ```
  """
  defmacro storybook_assets(path \\ @default_assets_path) do
    gzip_assets? = @gzip_assets

    quote bind_quoted: binding() do
      scope "/", PhxLiveStorybook do
        pipeline :storybook_assets do
          plug(Plug.Static,
            at: path,
            from: :phx_live_storybook,
            only: ~w(css js images favicon),
            gzip: gzip_assets?
          )
        end

        pipe_through(:storybook_assets)
        get("#{path}/*asset", AssetNotFoundController, :asset, as: :storybook_asset)
      end
    end
  end
end
