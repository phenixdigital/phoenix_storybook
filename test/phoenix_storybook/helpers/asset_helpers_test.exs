defmodule PhoenixStorybook.AssetHelpersTest do
  # async: false — the asset_hash tests share global :persistent_term state
  # and write scratch files under this library's priv/static.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import PhoenixStorybook.AssetHelpers

  alias PhoenixStorybook.AssetHelpers

  # Any file shipped in this library's priv/static works as a stand-in for a
  # host application asset — only its bytes matter for the hash.
  @existing_asset "favicon/favicon.ico"
  @missing_asset "js/missing.js"
  @scratch_asset "asset_helpers_test_scratch.css"

  defmodule HashedAssetsStorybook do
    use PhoenixStorybook,
      otp_app: :phoenix_storybook,
      content_path: Path.expand("../../fixtures/storybook_content/empty_files", __DIR__),
      css_path: "favicon/favicon.ico",
      js_path: "js/missing.js"
  end

  defmodule NoAssetsStorybook do
    use PhoenixStorybook,
      otp_app: :phoenix_storybook,
      content_path: Path.expand("../../fixtures/storybook_content/empty_files", __DIR__)
  end

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
      assert asset_file_name(manifest, "js/phoenix_storybook.js") ==
               "js/phoenix_storybook-95f46e7cf239d376ab8ff27958ffab1a.js"
    end

    test "it raises nil with wrong asset", %{manifest: manifest} do
      assert_raise RuntimeError, "cannot find asset js/wrong.js in manifest", fn ->
        asset_file_name(manifest, "js/wrong.js")
      end
    end
  end

  describe "asset_hash/3" do
    setup :reset_asset_hash_state
    setup :create_scratch_asset

    test "computes the md5 hash of the asset and caches it with its stat", %{path: path} do
      hash = asset_hash(:phoenix_storybook, :css_path, @scratch_asset)

      assert hash == md5(File.read!(path))

      assert {_mtime, _size, ^hash} =
               :persistent_term.get({AssetHelpers, :phoenix_storybook, @scratch_asset})
    end

    test "returns the cached hash while mtime and size are unchanged", %{path: path} do
      %File.Stat{mtime: mtime, size: size} = File.stat!(path, time: :posix)

      hash = asset_hash(:phoenix_storybook, :css_path, @scratch_asset)

      # same byte size and a forced identical mtime: the stat revalidation
      # cannot tell the file changed, so the cached hash is served
      File.write!(path, String.duplicate("B", size))
      File.touch!(path, mtime)

      assert asset_hash(:phoenix_storybook, :css_path, @scratch_asset) == hash
    end

    test "recomputes the hash when the asset is rebuilt", %{path: path} do
      hash = asset_hash(:phoenix_storybook, :css_path, @scratch_asset)

      File.write!(path, "body { color: blue }")
      %File.Stat{mtime: mtime} = File.stat!(path, time: :posix)
      File.touch!(path, mtime + 1)

      new_hash = asset_hash(:phoenix_storybook, :css_path, @scratch_asset)

      assert new_hash == md5("body { color: blue }")
      refute new_hash == hash
    end

    test "does not cache failed lookups" do
      log =
        capture_log(fn ->
          assert asset_hash(:phoenix_storybook, :js_path, @missing_asset) == nil
        end)

      assert log =~ "Can't resolve js_path"

      assert :persistent_term.get({AssetHelpers, :phoenix_storybook, @missing_asset}, :none) ==
               :none
    end

    test "returns nil and warns when the otp_app has no priv dir" do
      log =
        capture_log(fn ->
          assert asset_hash(:unknown_app, :css_path, "app.css") == nil
        end)

      assert log =~ "Can't resolve priv dir for application unknown_app"
    end
  end

  describe "generated asset_hash/1" do
    setup :reset_asset_hash_state

    test "returns the md5 hash of an existing asset, computed at runtime" do
      assert HashedAssetsStorybook.asset_hash(:css_path) == expected_hash()
    end

    test "returns nil and warns when the asset file is missing" do
      {result, log} = with_log(fn -> HashedAssetsStorybook.asset_hash(:js_path) end)

      assert result == nil
      assert log =~ "Can't resolve js_path"
    end

    test "returns nil when no asset path is configured" do
      assert NoAssetsStorybook.asset_hash(:css_path) == nil
      assert NoAssetsStorybook.asset_hash(:js_path) == nil
    end

    test "does not record user assets as external resources" do
      resources =
        HashedAssetsStorybook.__info__(:attributes)
        |> Keyword.get_values(:external_resource)
        |> List.flatten()

      refute Enum.any?(resources, fn resource ->
               String.ends_with?(to_string(resource), [@existing_asset, @missing_asset])
             end)
    end
  end

  defp expected_hash do
    content =
      [:code.priv_dir(:phoenix_storybook), "static", @existing_asset]
      |> Path.join()
      |> File.read!()

    Base.encode16(:crypto.hash(:md5, content), case: :lower)
  end

  defp reset_asset_hash_state(_context) do
    clear_asset_hash_cache()
    on_exit(&clear_asset_hash_cache/0)
    :ok
  end

  defp create_scratch_asset(_context) do
    path =
      [:code.priv_dir(:phoenix_storybook), "static", @scratch_asset]
      |> Path.join()

    File.write!(path, "body { color: red }")
    on_exit(fn -> File.rm(path) end)

    {:ok, path: path}
  end

  defp md5(content) do
    Base.encode16(:crypto.hash(:md5, content), case: :lower)
  end

  defp clear_asset_hash_cache do
    for {key, _value} <- :persistent_term.get(), match?({AssetHelpers, _, _}, key) do
      :persistent_term.erase(key)
    end
  end

  defp manifest_path(manifest) do
    ["..", "..", "fixtures", "asset_manifests", manifest] |> Path.join() |> Path.expand(__DIR__)
  end
end
