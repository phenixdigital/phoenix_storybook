defmodule PhxLiveStorybook.ExsLoaderTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias PhxLiveStorybook.ExsLoader

  setup do
    [
      path: Path.expand("../fixtures/exs", __DIR__),
      exs: "script.exs",
      bad_exs: "bad_script.exs"
    ]
  end

  describe "load_exs/2" do
    test "can load an exs", %{exs: exs, path: path} do
      assert ExsLoader.load_exs(exs, path) == PhxLiveStorybook.Script
    end

    test "can load same exs twice", %{exs: exs, path: path} do
      assert ExsLoader.load_exs(exs, path) == PhxLiveStorybook.Script
      assert ExsLoader.load_exs(exs, path) == PhxLiveStorybook.Script
    end

    test "can load an exs in immediate mode", %{exs: exs, path: path} do
      assert ExsLoader.load_exs(exs, path, immediate: true) == PhxLiveStorybook.Script
    end

    test "returns nil with bad script", %{bad_exs: exs, path: path} do
      log = capture_log(fn -> assert is_nil(ExsLoader.load_exs(exs, path)) end)
      assert log =~ ~s|could not compile "#{exs}"|
    end
  end
end
