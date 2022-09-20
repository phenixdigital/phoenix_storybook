defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  alias Makeup.Styles.HTML.StyleMap
  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.AssetHelpers
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  @env Application.compile_env(:phx_live_storybook, :env)

  def render_breadcrumb(socket, story_path, opts \\ []) do
    breadcrumb(socket, story_path)
    |> Enum.intersperse(:separator)
    |> Enum.map_join("", fn
      :separator ->
        ~s|<i class="lsb fat fa-angle-right lsb-px-2 lsb-text-slate-500"></i>|

      story_name ->
        ~s|<span class="lsb #{opts[:span_class]} [&:not(:last-child)]:lsb-truncate last:lsb-whitespace-nowrap">#{story_name}</span>|
    end)
    |> raw()
  end

  defp makeup_stylesheet(conn) do
    style = storybook_setting(conn, :makeup_style, :monokai_style)
    apply(StyleMap, style, []) |> Makeup.stylesheet()
  end

  defp live_socket_path(conn = %Plug.Conn{}) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  defp storybook_css_path(conn), do: storybook_setting(conn, :css_path)
  defp storybook_js_path(conn), do: storybook_setting(conn, :js_path)

  defp title(socket) do
    storybook_setting(socket, :title, "Live Storybook")
  end

  defp storybook_setting(conn_or_socket, key, default \\ nil)

  defp storybook_setting(conn_or_socket, key, default) do
    backend_module = backend_module(conn_or_socket)
    backend_module.config(key, default)
  end

  defp backend_module(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.backend_module
  defp backend_module(conn = %Plug.Conn{}), do: conn.private.backend_module

  defp assets_path(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.assets_path
  defp assets_path(conn = %Plug.Conn{}), do: conn.private.assets_path

  defp application_static_path(conn, path) do
    routes(conn).static_path(conn, path)
  end

  defp asset_path(conn_or_socket, path) do
    assets_path = assets_path(conn_or_socket)
    Path.join(assets_path, asset_file_name(path, @env))
  end

  @manifest_path Path.expand("static/cache_manifest.json", :code.priv_dir(:phx_live_storybook))
  @external_resource @manifest_path
  @manifest AssetHelpers.parse_manifest(@manifest_path, @env)
  defp asset_file_name(asset, :prod) do
    if String.ends_with?(asset, [".js", ".css"]) do
      @manifest |> AssetHelpers.asset_file_name(asset, :prod)
    else
      asset
    end
  end

  defp asset_file_name(path, _env), do: path

  defp breadcrumb(socket, story_path) do
    backend_module = backend_module(socket)

    {_, breadcrumb} =
      for path_item <- Path.split(story_path), reduce: {"", []} do
        {path, breadcrumb} ->
          path = Path.join(["/", path, path_item])

          case backend_module.find_entry_by_path(path) do
            %FolderEntry{nice_name: nice_name} -> {path, [nice_name | breadcrumb]}
            %ComponentEntry{name: name} -> {path, [name | breadcrumb]}
            %PageEntry{name: name} -> {path, [name | breadcrumb]}
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

  defp show_dropdown_transition do
    {"lsb-ease-out lsb-duration-200", "lsb-opacity-0 lsb-scale-95",
     "lsb-opacity-100 lsb-scale-100"}
  end

  defp hide_dropdown_transition do
    {"lsb-ease-out lsb-duration-200", "lsb-opacity-100 lsb-scale-100",
     "lsb-opacity-0 lsb-scale-95"}
  end

  def sandbox_class(%{theme: nil}), do: "lsb-sandbox"
  def sandbox_class(%{theme: theme}), do: "lsb-sandbox theme-#{theme}"
end
