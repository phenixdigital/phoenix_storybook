defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}
  alias Makeup.Styles.HTML.StyleMap

  js_path = Path.join(__DIR__, "../../../dist/js/app.js")
  css_path = Path.join(__DIR__, "../../../dist/css/app.css")

  @external_resource js_path
  @external_resource css_path

  @app_js File.read!(js_path)
  @app_css File.read!(css_path)

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css

  def makeup_stylesheet(conn), do: makeup_style(conn) |> Makeup.stylesheet()

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  def storybook_entries(conn), do: conn.private.backend_module.storybook_entries()

  def storybook_css_path(conn), do: storybook_setting(conn, :css_path)
  def storybook_js_path(conn), do: storybook_setting(conn, :js_path)
  def title(conn), do: storybook_setting(conn, :storybook_title)
  def makeup_style(conn), do: storybook_setting(conn, :makeup_style, StyleMap.tango_style())

  def storybook_setting(conn, key, default \\ nil) do
    otp_app = conn.private.otp_app
    backend_module = conn.private.backend_module
    Application.get_env(otp_app, backend_module, []) |> Keyword.get(key, default)
  end

  def module_name(mod), do: mod |> to_string() |> String.split(".") |> Enum.at(-1)
end
