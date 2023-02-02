defmodule PhoenixStorybook.AssetHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixStorybook.AssetHelpers

  describe "parse_manifest/2" do
    test "it parses a valid manifest" do
      path = manifest_path("cache_manifest.json")
      assert is_map(parse_manifest(path))
    end

    test "it raises when path is invalid" do
      path = manifest_path("unknown.json")

      assert_raise RuntimeError, "cannot read manifest #{path}", fn ->
        parse_manifest(path)
      end
    end

    test "it raises when manifest is corrupted" do
      path = manifest_path("corrupted_manifest.json")

      assert_raise RuntimeError, "cannot read manifest #{path}", fn ->
        parse_manifest(path)
      end
    end
  end

  describe "asset_file_name/3" do
    setup do
      {:ok, manifest: manifest_path("cache_manifest.json") |> parse_manifest()}
    end

    test "it returns fingerprinted asset name", %{manifest: manifest} do
      assert asset_file_name(manifest, "js/app.js", :prod) ==
               "js/app-95f46e7cf239d376ab8ff27958ffab1a.js"
    end

    test "it raises nil with wrong asset", %{manifest: manifest} do
      assert_raise RuntimeError, "cannot find asset js/wrong.js in manifest", fn ->
        asset_file_name(manifest, "js/wrong.js", :prod)
      end
    end

    test "it returns nil when not in production", %{manifest: manifest} do
      assert is_nil(asset_file_name(manifest, "js/app.js", :dev))
    end
  end

  defp manifest_path(manifest) do
    ["..", "..", "fixtures", "asset_manifests", manifest] |> Path.join() |> Path.expand(__DIR__)
  end
end
