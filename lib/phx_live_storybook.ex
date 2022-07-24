defmodule PhxLiveStorybook do
  @moduledoc """
  PhxLiveStorybook provides the core functions to discover _entries_
  from your storybook and recompile everything as they are updated.

  It also provides function to read storybook settings from your
  application config files.

  ## Behavior

  _PhxLiveStorybook_ is meant to be used in a module of your own, later
  referenced as your __backend module__.

  It allows automatic discovery of storybook entries under `:content_path`
  and automatically generate storybook navigation sidebar. Feel free to
  organize them in sub-folders, as the hierarchy will be respected in your
  sidebar.

  Every module detected in your content folder, will be loaded and identified
  as a storybook entry. For now two kind of entries are supported:
  - `component` to describe your stateless function components
  - `live_component` to describe your live components.

  See `PhxLiveStorybook.Entry` for more details.

  ## Usage

  You first need to define your __backend module__.

  ```elixir
  # lib/my_app_web/storybook.ex
  defmodule MyAppWeb.Storybook do
    use PhxLiveStorybook, otp_app: :my_app
  end
  ```

  Which should be configured as such. Only `:content_path` is required.

  ```elixir
  # config/config.exs
  config :my_app, MyAppWeb.Storybook,

    # Path to your storybook entries (required).
    content_path: Path.expand("../my_app_web/lib/storybook", __DIR__),

    # Each entry module is loaded from camelized HTTP request path (ie. `"/components/button"`)
    # prefixed by the following. Default is your backend module.
    entries_module_prefix: MyAppWeb.Storybook,

    # Path to your components stylesheet.
    css_path: "/assets/my_components.css",

    # Path to your JS asset, which will be loaded just before PhxLiveStorybook's own
    # JS. It's mainly intended to define your own LiveView Hooks in `window.storybook.Hooks`.
    js_path: "/assets/my_components.js",

    # Custom storybook title. Default is "Live Storybook".
    title: "My Live Storybook",

    # Folder settings.
    # Each folder is designated by its relative path from the storybook mounting point.
    # For each folder you can:
    # - make it open by defaut in the sidebar, with `open: true`.
    # - give it a custom icon in the sidebar, with a FontAwesome 6+ CSS class.
    folders: [
      components: [icon: "far fa-toolbox", open: true],
      "components/live": [icon: "fal fa-bolt"]
    ]
  ```
  """

  alias PhxLiveStorybook.Entries

  @doc false
  defmacro __using__(opts) do
    [quotes(opts), Entries.quotes(opts)]
  end

  defp quotes(opts) do
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
