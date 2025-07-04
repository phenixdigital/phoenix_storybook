defmodule PhoenixStorybook.JSAssets do
  # Plug to serve dependency-specific assets for the dashboard.
  @moduledoc false
  import Plug.Conn

  phoenix_js_paths =
    for app <- [:phoenix, :phoenix_live_view] do
      path = Application.app_dir(app, ["priv", "static", "#{app}.js"])
      Module.put_attribute(__MODULE__, :external_resource, path)
      path
    end

  js_path = Path.join(__DIR__, "../../../priv/static/js/phoenix_storybook.js")
  @external_resource js_path

  iframe_js_path = Path.join(__DIR__, "../../../priv/static/js/phoenix_storybook_iframe.js")
  @external_resource iframe_js_path

  @js """
  #{for path <- phoenix_js_paths, do: path |> File.read!() |> String.replace("//# sourceMappingURL=", "// ")}
  #{File.read!(js_path)}
  """

  @iframe_js """
  #{for path <- phoenix_js_paths, do: path |> File.read!() |> String.replace("//# sourceMappingURL=", "// ")}
  #{File.read!(iframe_js_path)}
  """

  @hashes %{
    :js => Base.encode16(:crypto.hash(:md5, @js), case: :lower),
    :iframe_js => Base.encode16(:crypto.hash(:md5, @iframe_js), case: :lower)
  }

  def init(asset) when asset in [:css, :fontscss, :js, :iframejs], do: asset

  def call(conn, asset) do
    conn
    |> put_resp_header("content-type", "text/javascript")
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, content(asset))
    |> halt()
  end

  defp content(:js), do: @js
  defp content(:iframejs), do: @iframe_js

  @doc """
  Returns the current hash for the given `asset`.
  """
  def current_hash(:js), do: @hashes.js
  def current_hash(:iframe_js), do: @hashes.iframe_js
end
