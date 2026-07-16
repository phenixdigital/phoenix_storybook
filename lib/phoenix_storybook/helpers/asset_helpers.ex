defmodule PhoenixStorybook.AssetHelpers do
  @moduledoc false

  require Logger

  # MD5 hash of a js/css asset provided by the host application (`:css_path` /
  # `:js_path` options), used as a cache-busting query param by the storybook
  # layout.
  #
  # These assets may not exist when the backend module is compiled (asset
  # pipelines run separately from `mix compile`), so hashes are computed at
  # runtime. The hash is cached in `:persistent_term` and revalidated on each
  # call with a File.stat — mtime + size, as Plug.Static does for ETags — so
  # the file is never re-read or re-hashed per render, while assets rebuilt
  # under a running server (e.g. by dev watchers) pick up a fresh hash
  # automatically.
  def asset_hash(otp_app, asset, asset_path) do
    case :code.priv_dir(otp_app) do
      {:error, :bad_name} ->
        Logger.warning("Can't resolve priv dir for application #{otp_app}")
        nil

      priv_dir ->
        path = priv_dir |> Path.join("static") |> Path.join(asset_path)

        case File.stat(path, time: :posix) do
          {:ok, %File.Stat{mtime: mtime, size: size}} ->
            key = {__MODULE__, otp_app, asset_path}

            case :persistent_term.get(key, nil) do
              {^mtime, ^size, hash} -> hash
              _ -> compute_asset_hash(key, path, asset, mtime, size)
            end

          {:error, _} ->
            warn_missing_asset(asset, path)
            nil
        end
    end
  end

  defp compute_asset_hash(key, path, asset, mtime, size) do
    case File.read(path) do
      {:ok, content} ->
        hash = Base.encode16(:crypto.hash(:md5, content), case: :lower)
        :persistent_term.put(key, {mtime, size, hash})
        hash

      # the file was removed between stat and read
      {:error, _} ->
        warn_missing_asset(asset, path)
        nil
    end
  end

  defp warn_missing_asset(asset, path) do
    Logger.warning(
      "Can't resolve #{asset}: #{path} not found (storybook assets are built by `mix assets.build`)"
    )
  end

  def parse_manifest(manifest_path) do
    with {:ok, manifest_json} <- File.read(manifest_path),
         {:ok, manifest_body} <- Jason.decode(manifest_json) do
      manifest_body
    else
      _ -> raise "cannot read manifest #{manifest_path}"
    end
  end

  def asset_file_name(manifest, asset) do
    case manifest |> Map.get("latest", %{}) |> Map.get(asset) do
      nil -> raise "cannot find asset #{asset} in manifest"
      asset -> asset
    end
  end
end
