defmodule PhxLiveStorybook.AssetsController do
  use PhxLiveStorybook.Web, :controller

  app_js_path = Path.join(__DIR__, "../../../dist/js/app.js")
  iframe_js_path = Path.join(__DIR__, "../../../dist/js/iframe.js")
  app_css_path = Path.join(__DIR__, "../../../dist/css/app.css")

  @external_resource app_js_path
  @external_resource iframe_js_path
  @external_resource app_css_path

  @app_js File.read!(app_js_path)
  @app_js_gz :zlib.compress(@app_js)
  @app_js_hash PhxLiveStorybook.HashHelpers.hash(@app_js)

  @iframe_js File.read!(iframe_js_path)
  @iframe_js_gz :zlib.compress(@iframe_js)
  @iframe_js_hash PhxLiveStorybook.HashHelpers.hash(@iframe_js)

  @app_css File.read!(app_css_path)
  @app_css_gz :zlib.compress(@app_css)
  @app_css_hash PhxLiveStorybook.HashHelpers.hash(@app_css)

  def show(conn, %{"asset" => "app-#{@app_js_hash}.js"}) do
    send_asset(conn, @app_js, "text/javascript")
  end

  def show(conn, %{"asset" => "app-#{@app_js_hash}.js.gz"}) do
    send_asset(conn, @app_js_gz, "application/javascript")
  end

  def show(conn, %{"asset" => "iframe-#{@iframe_js_hash}.js"}) do
    send_asset(conn, @iframe_js, "application/javascript")
  end

  def show(conn, %{"asset" => "iframe-#{@iframe_js_hash}.js.gz"}) do
    send_asset(conn, @iframe_js_gz, "application/javascript")
  end

  def show(conn, %{"asset" => "app-#{@app_css_hash}.css"}) do
    send_asset(conn, @app_css, "text/css")
  end

  def show(conn, %{"asset" => "app-#{@app_css_hash}.css.gz"}) do
    send_asset(conn, @app_css_gz, "text/css")
  end

  def show(_conn, _params), do: raise(PhxLiveStorybook.AssetNotFound)

  #   Content-Type: application/javascript
  # Content-Encoding: gzip
  defp send_asset(conn, content, content_type) do
    conn
    |> Plug.Conn.put_resp_header("Cache-control", "max-age=31536000")
    |> Plug.Conn.put_resp_header("content-type", content_type)
    |> Plug.Conn.send_resp(200, content)
  end
end

defmodule PhxLiveStorybook.AssetNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
