defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  alias Makeup.Styles.HTML.StyleMap
  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  js_path = Path.join(__DIR__, "../../../dist/js/app.js")
  css_path = Path.join(__DIR__, "../../../dist/css/app.css")

  @external_resource js_path
  @external_resource css_path

  @app_js File.read!(js_path)
  @app_css File.read!(css_path)

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css

  defp makeup_stylesheet(conn) do
    style = storybook_setting(conn, :makeup_style, :monokai_style)
    apply(StyleMap, style, []) |> Makeup.stylesheet()
  end

  defp live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  defp storybook_css_path(conn), do: storybook_setting(conn, :css_path)
  defp storybook_js_path(conn), do: storybook_setting(conn, :js_path)

  defp title(socket) do
    storybook_setting(socket, :storybook_title, "Live Storybook")
  end

  defp storybook_setting(conn_or_socket, key, default \\ nil)

  defp storybook_setting(conn_or_socket, key, default) do
    otp_app = otp_app(conn_or_socket)
    backend_module = backend_module(conn_or_socket)
    Application.get_env(otp_app, backend_module, []) |> Keyword.get(key, default)
  end

  defp render_breadcrumb(socket, entry) do
    breadcrumb(socket, entry)
    |> Enum.intersperse(:separator)
    |> Enum.map_join("", fn
      :separator -> ~s|<i class="fat fa-angle-right lsb-px-2 lsb-text-slate-500"></i>|
      entry_name -> ~s|<span>#{entry_name}</span>|
    end)
    |> raw()
  end

  defp otp_app(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.otp_app
  defp otp_app(conn = %Plug.Conn{}), do: conn.private.otp_app

  defp backend_module(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.backend_module
  defp backend_module(conn = %Plug.Conn{}), do: conn.private.backend_module

  defp application_static_path(conn, path) do
    router = conn.private.application_router
    :"#{router}.Helpers".static_path(conn, path)
  end

  defp breadcrumb(socket, entry) do
    backend_module = backend_module(socket)

    {_, breadcrumb} =
      for path_item <- String.split(entry.storybook_path, "/", trim: true), reduce: {"", []} do
        {path, breadcrumb} ->
          path = path <> "/" <> path_item

          case backend_module.find_entry_by_path(path) do
            %FolderEntry{nice_name: nice_name} -> {path, [nice_name | breadcrumb]}
            %ComponentEntry{name: name} -> {path, [name | breadcrumb]}
            %PageEntry{name: name} -> {path, [name | breadcrumb]}
          end
      end

    Enum.reverse(breadcrumb)
  end
end
