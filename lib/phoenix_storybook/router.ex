defmodule PhoenixStorybook.Router do
  @moduledoc """
  Provides LiveView routing for storybook.
  """

  @doc """
  Defines a PhoenixStorybook route.

  It expects the `path` the storybook will be mounted at and a set of options.

  This will also generate a named helper called `live_storybook_path/2` which you can use to link
  directly to the storybook, such as:

  ```elixir
  <.link href={live_storybook_path(conn, :root)} />
  ```

  Note that you should only use the `href` attribute to link to the storybook,
  as it has to set its own session on first rendering. Linking with `patch` or
  `navigate` will not work.

  ## Options

    * `:backend_module` - _Required_ - Name of your backend module.
    * `:live_socket_path` - Configures the socket path. It must match the
      `socket "/live", Phoenix.LiveView.Socket` in your endpoint.
    * `:assets_path` - Configures the assets path. It must match the `storybook_assets` in your
       router. Defaults to `"/storybook/assets"`.
    * `:session_name` - Configures the live session name. Defaults to `:live_storybook`. Use this
       option if you want to mount multiple storybooks in the same router.
    * `:as` - Allows you to set the route helper name. Defaults to`:live_storybook`.
    * `:pipeline` - Set to `false` if you don't want a router pipeline to be created. This is useful
       if you want to define your own `:storybook_browser` pipeline, or if you mount multiple
       storybooks, in which case the pipeline only has to be defined once. Defaults to `true`.

  ## Usage

  ```elixir
  # lib/my_app_web/router.ex
  use MyAppWeb, :router
  import PhoenixStorybook.Router
  ...

  scope "/" do
    pipe_through :browser
    live_storybook "/storybook", backend_module: MyAppWeb.Storybook
  end
  ```

  Note that it is not possible to use this macro in a scope with a path
  different from `/`.
  """
  defmacro live_storybook(path, opts) do
    opts =
      opts
      |> Keyword.put(:application_router, __CALLER__.module)
      |> Keyword.put_new(:as, :live_storybook)
      |> Keyword.put_new(:pipeline, true)

    session_name_opt = Keyword.get(opts, :session_name, :live_storybook)
    session_name_iframe_opt = :"#{session_name_opt}_iframe"

    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        if Keyword.fetch!(opts, :pipeline) do
          pipeline :storybook_browser do
            plug :accepts, ["html"]
            plug :fetch_session
            plug :protect_from_forgery
          end
        end

        scope path: "/" do
          pipe_through(:storybook_browser)

          {session_name, session_opts, route_opts} =
            PhoenixStorybook.Router.__options__(opts, path, session_name_iframe_opt, :root_iframe)

          live_session session_name, session_opts do
            live "/visual_tests", PhoenixStorybook.VisualTestLive, :range, route_opts
            live "/visual_tests/*story", PhoenixStorybook.VisualTestLive, :show, route_opts

            live "/iframe/*story",
                 PhoenixStorybook.Story.ComponentIframeLive,
                 :story_iframe,
                 route_opts
          end

          {session_name, session_opts, route_opts} =
            PhoenixStorybook.Router.__options__(opts, path, session_name_opt, :root)

          live_session session_name, session_opts do
            live "/", PhoenixStorybook.StoryLive, :root, route_opts
            live "/*story", PhoenixStorybook.StoryLive, :story, route_opts
          end
        end
      end
    end
  end

  @default_assets_path "/storybook/assets"

  @doc false
  def __options__(opts, path, session_name, root_layout) do
    live_socket_path = Keyword.get(opts, :live_socket_path, "/live")
    assets_path = Keyword.get(opts, :assets_path, @default_assets_path)

    backend_module =
      Keyword.get_lazy(opts, :backend_module, fn ->
        raise "Missing mandatory :backend_module option."
      end)

    {
      session_name,
      [
        root_layout: {PhoenixStorybook.LayoutView, root_layout},
        on_mount: PhoenixStorybook.Mount,
        session: %{
          "backend_module" => backend_module,
          "assets_path" => assets_path,
          "root_path" => path
        }
      ],
      [
        private: %{
          live_socket_path: live_socket_path,
          backend_module: backend_module,
          application_router: Keyword.get(opts, :application_router),
          assets_path: assets_path
        },
        as: Keyword.fetch!(opts, :as)
      ]
    }
  end

  @gzip_assets Application.compile_env(:phoenix_storybook, :gzip_assets, false)

  @doc """
  Defines routes for PhoenixStorybook static assets.

  Static assets should not be CSRF protected. So they need to be mounted in your
  router in a different pipeline than storybook's.

  It can take the `path` the storybook assets will be mounted at.
  Default path is `"/storybook/assets"`.

  ## Usage

  ```elixir
  # lib/my_app_web/router.ex
  use MyAppWeb, :router
  import PhoenixStorybook.Router
  ...

  scope "/" do
    storybook_assets()
  end
  ```
  """
  defmacro storybook_assets(path \\ @default_assets_path) do
    gzip_assets? = @gzip_assets

    quote bind_quoted: binding() do
      scope "/", PhoenixStorybook do
        pipeline :storybook_assets do
          plug Plug.Static,
            at: path,
            from: :phoenix_storybook,
            only: ~w(css js images fonts favicon),
            gzip: gzip_assets?
        end

        pipe_through :storybook_assets
        get "#{path}/*asset", AssetNotFoundController, :asset, as: :storybook_asset
      end
    end
  end
end
