defmodule PhxLiveStorybook.AssetHelpers do
  @moduledoc false

  def parse_manifest(manifest_path, :prod) do
    with {:ok, manifest_json} <- File.read(manifest_path),
         {:ok, manifest_body} <- Jason.decode(manifest_json) do
      manifest_body
    else
      _ -> raise "cannot read manifest #{manifest_path}"
    end
  end

  def parse_manifest(_manifest_path, _), do: nil

  def asset_file_name(manifest, asset, :prod) do
    case manifest |> Map.get("latest", %{}) |> Map.get(asset) do
      nil -> raise "cannot find asset #{asset} in manifest"
      asset -> asset
    end
  end

  def asset_file_name(_manifest, _asset, _env), do: nil
end
