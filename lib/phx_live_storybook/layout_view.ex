defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  js_path = Path.join(__DIR__, "../../dist/js/app.js")
  css_path = Path.join(__DIR__, "../../dist/css/app.css")

  @external_resource js_path
  @external_resource css_path

  @app_js File.read!(js_path)
  @app_css File.read!(css_path)

  @storybook_backend Application.compile_env(:phx_live_storybook, :storybook_backend)

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  def storybook_entries do
    apply(@storybook_backend, :storybook_entries, [])
  end
end
