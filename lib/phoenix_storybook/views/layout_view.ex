defmodule PhoenixStorybook.LayoutView do
  @moduledoc false
  use Phoenix.Component
  use PhoenixStorybook.Web, :view

  alias Makeup.Styles.HTML.StyleMap
  alias Phoenix.LiveView.{JS, Socket}
  alias PhoenixStorybook.AssetHelpers
  alias PhoenixStorybook.{FolderEntry, StoryEntry}
  alias PhoenixStorybook.ThemeHelpers

  def render_breadcrumb(socket, story_path, opts \\ []) do
    assigns = %{
      breadcrumbs: breadcrumb(socket, story_path),
      fa_plan: backend_module(socket).config(:font_awesome_plan, :free),
      span_class: opts[:span_class]
    }

    ~H"""
    <.intersperse :let={item} enum={@breadcrumbs}>
      <:separator>
        <.fa_icon
          style={:thin}
          name="angle-right"
          class="psb-px-2 psb-text-slate-500 dark:psb-text-slate-300"
          plan={@fa_plan}
        />
      </:separator>
      <span class={[
        "psb",
        @span_class,
        "[&:not(:last-child)]:psb-truncate last:psb-whitespace-nowrap"
      ]}>
        {item}
      </span>
    </.intersperse>
    """
  end

  defp makeup_stylesheet(conn) do
    style = storybook_setting(conn, :makeup_style, :monokai_style)
    apply(StyleMap, style, []) |> Makeup.stylesheet()
  end

  def live_socket_path(socket = %Socket{}) do
    full_live_socket_path(
      socket.endpoint.script_name(),
      fetch_assign(socket, :live_socket_path)
    )
  end

  def live_socket_path(conn) do
    full_live_socket_path(
      conn.script_name,
      conn.private.live_socket_path
    )
  end

  defp full_live_socket_path(script_name, socket_path) do
    [Enum.map(script_name, &["/" | &1]) | socket_path]
  end

  def storybook_css_path(conn), do: storybook_setting(conn, :css_path)
  def storybook_js_path(conn), do: storybook_setting(conn, :js_path)
  def storybook_js_type(conn), do: storybook_setting(conn, :js_script_type, "text/javascript")

  defp title(conn_or_socket), do: storybook_setting(conn_or_socket, :title, "Live Storybook")

  defp title_prefix(conn_or_socket) do
    title(conn_or_socket) <> " - "
  end

  def fa_kit_id(conn_or_socket) do
    storybook_setting(conn_or_socket, :font_awesome_kit_id)
  end

  def csrf?(socket = %Socket{}), do: fetch_assign(socket, :csrf)
  def csrf?(conn = %Plug.Conn{}), do: conn.private.csrf

  def csp_nonce(%Plug.Conn{} = conn, type) when type in [:script, :style, :img] do
    csp_nonce_assign_key = conn.private.csp_nonce_assign_key[type]
    conn.assigns[csp_nonce_assign_key]
  end

  def csp_nonce(socket = %Socket{}, type)
      when type in [:script, :style, :img] do
    csp_nonces = fetch_assign(socket, :csp_nonces)
    csp_nonces[type]
  end

  # for liveview
  def csp_nonce(csp_nonces, type) when type in [:script, :style, :img] do
    csp_nonces[type]
  end

  defp storybook_setting(conn_or_socket, key, default \\ nil)

  defp storybook_setting(conn_or_socket, key, default) do
    backend_module = backend_module(conn_or_socket)
    backend_module.config(key, default)
  end

  defp backend_module(s = %Socket{}), do: s.assigns.__assigns__.backend_module
  defp backend_module(conn = %Plug.Conn{}), do: conn.private.backend_module

  defp assets_path(s = %Socket{}), do: s.assigns.__assigns__.assets_path
  defp assets_path(conn = %Plug.Conn{}), do: conn.private.assets_path

  def application_static_path(path), do: Path.join("/", path)

  def asset_path(conn_or_socket, path) do
    assets_path = assets_path(conn_or_socket)
    Path.join(assets_path, asset_file_name(path))
  end

  @manifest_path Path.expand("static/cache_manifest.json", :code.priv_dir(:phoenix_storybook))
  @external_resource @manifest_path

  if Application.compile_env(:phoenix_storybook, :env) == :prod do
    @manifest AssetHelpers.parse_manifest(@manifest_path)

    defp asset_file_name(asset) do
      if String.ends_with?(asset, [".js", ".css"]) do
        @manifest |> AssetHelpers.asset_file_name(asset, :prod)
      else
        asset
      end
    end
  else
    defp asset_file_name(path), do: path
  end

  defp breadcrumb(socket, story_path) do
    backend_module = backend_module(socket)

    {_, breadcrumb} =
      for path_item <- Path.split(story_path), reduce: {"", []} do
        {path, breadcrumb} ->
          path = Path.join(["/", path, path_item])

          case backend_module.find_entry_by_path(path) do
            %FolderEntry{name: name} -> {path, [name | breadcrumb]}
            %StoryEntry{name: name} -> {path, [name | breadcrumb]}
            nil -> {path, breadcrumb}
          end
      end

    Enum.reverse(breadcrumb)
  end

  defp themes(socket) do
    backend_module = backend_module(socket)
    backend_module.config(:themes, nil)
  end

  defp current_theme_dropdown_class(socket, assigns) do
    themes = themes(socket)
    current_theme = Map.get(assigns, :theme)

    case Enum.find(themes, fn {theme, _} -> theme == current_theme end) do
      nil -> ""
      {_, opts} -> Keyword.get(opts, :dropdown_class)
    end
  end

  defp color_mode?(socket) do
    backend_module = backend_module(socket)
    backend_module.config(:color_mode, false)
  end

  defp color_mode_icon("light"), do: "brightness"
  defp color_mode_icon("dark"), do: "moon"
  defp color_mode_icon(_), do: "circle-half-stroke"

  defp show_dropdown_transition do
    {"psb-ease-out psb-duration-200", "psb-opacity-0 psb-scale-95",
     "psb-opacity-100 psb-scale-100"}
  end

  defp hide_dropdown_transition do
    {"psb-ease-out psb-duration-200", "psb-opacity-100 psb-scale-100",
     "psb-opacity-0 psb-scale-95"}
  end

  def sandbox_class(conn_or_socket, container, %{theme: nil}) do
    main_sandbox_class(conn_or_socket, container)
  end

  def sandbox_class(conn_or_socket, container, %{theme: theme}) do
    backend_module = backend_module(conn_or_socket)

    [
      ThemeHelpers.theme_sandbox_class(backend_module, theme)
      | main_sandbox_class(conn_or_socket, container)
    ]
  end

  defp main_sandbox_class(conn_or_socket, {_container, container_opts}) do
    container_class = Keyword.get(container_opts, :class)
    ["psb-sandbox", container_class, backend_module(conn_or_socket).config(:sandbox_class)]
  end

  defp fetch_assign(socket, assign) do
    case socket.assigns do
      %Phoenix.LiveView.Socket.AssignsNotInSocket{__assigns__: assigns} ->
        Map.get(assigns, assign)

      assigns ->
        Map.get(assigns, assign)
    end
  end

  @default_div_class "psb-flex psb-flex-col psb-items-center psb-gap-y-[5px] psb-p-[5px]"
  def normalize_story_container(:div), do: {:div, class: @default_div_class}

  def normalize_story_container({:div, opts}),
    do: {:div, Keyword.put_new(opts, :class, @default_div_class)}

  @default_iframe_style "display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; padding: 5px;"
  def normalize_story_container(:iframe), do: {:iframe, style: @default_iframe_style}

  def normalize_story_container({:iframe, opts}),
    do: {:iframe, Keyword.put_new(opts, :style, @default_iframe_style)}

  def normalize_story_container({container, opts}), do: {container, opts}
end
