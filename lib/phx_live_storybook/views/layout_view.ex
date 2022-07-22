defmodule PhxLiveStorybook.LayoutView do
  @moduledoc false
  use PhxLiveStorybook.Web, :view

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  js_path = Path.join(__DIR__, "../../../dist/js/app.js")
  css_path = Path.join(__DIR__, "../../../dist/css/app.css")

  @external_resource js_path
  @external_resource css_path

  @app_js File.read!(js_path)
  @app_css File.read!(css_path)

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css

  def makeup_stylesheet, do: makeup_style() |> Makeup.stylesheet()

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  def storybook_css_path, do: storybook_setting(:css_path)
  def storybook_js_path, do: storybook_setting(:js_path)
  def title, do: storybook_setting(:storybook_title)
  def storybook_entries, do: storybook_setting(:storybook_entries)
  def makeup_style, do: storybook_setting(:makeup_style)

  def storybook_setting(key), do: apply(storybook_backend(), key, [])

  defp storybook_backend, do: Application.get_env(:phx_live_storybook, :backend_module)

  def module_name(mod), do: mod |> to_string() |> String.split(".") |> Enum.at(-1)
end
