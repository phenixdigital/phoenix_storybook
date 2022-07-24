defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  alias Makeup.Styles.HTML.StyleMap

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

  defp title(conn) do
    storybook_setting(conn, :storybook_title, "Live Storybook")
  end

  defp storybook_setting(conn, key, default \\ nil) do
    otp_app = conn.private.otp_app
    backend_module = conn.private.backend_module
    Application.get_env(otp_app, backend_module, []) |> Keyword.get(key, default)
  end
end
