defmodule PhoenixStorybook.ExsCompilerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias PhoenixStorybook.ExsCompiler

  setup do
    [
      path: Path.expand("../fixtures/exs", __DIR__),
      exs: "script.exs",
      bad_exs: "bad_script.exs"
    ]
  end

  describe "compile_exs/2" do
    test "can load an exs", %{exs: exs, path: path} do
      assert ExsCompiler.compile_exs(exs, path) == {:ok, PhoenixStorybook.Script}
    end

    test "can load same exs twice", %{exs: exs, path: path} do
      assert ExsCompiler.compile_exs(exs, path) == {:ok, PhoenixStorybook.Script}
      assert ExsCompiler.compile_exs(exs, path) == {:ok, PhoenixStorybook.Script}
    end

    test "returns an error tuple with bad script", %{bad_exs: exs, path: path} do
      log = capture_log(fn -> assert {:error, _, _} = ExsCompiler.compile_exs(exs, path) end)
      assert log =~ ~s|Could not compile "#{exs}"|
    end
  end

  describe "compile_exs!/2" do
    test "can load a valid exs", %{exs: exs, path: path} do
      assert ExsCompiler.compile_exs!(exs, path) == PhoenixStorybook.Script
    end

    test "it raises with bad script", %{bad_exs: exs, path: path} do
      assert_raise TokenMissingError, fn ->
        ExsCompiler.compile_exs!(exs, path)
      end
    end
  end
end
