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
    test "can load a valid exs, logs nothing by default", %{exs: exs, path: path} do
      log =
        capture_log(fn ->
          assert ExsCompiler.compile_exs!(exs, path) == PhoenixStorybook.Script
        end)

      refute log =~ "compiling"
    end

    test "it raises with bad script", %{bad_exs: exs, path: path} do
      assert_raise TokenMissingError, fn ->
        ExsCompiler.compile_exs!(exs, path)
      end
    end

    test "it logs when compilation_debug is set to true", %{
      exs: exs,
      path: path
    } do
      previous_logger_level = Logger.level()
      Logger.configure(level: :debug)

      log =
        capture_log(fn ->
          assert ExsCompiler.compile_exs!(exs, path, compilation_debug: true) ==
                   PhoenixStorybook.Script
        end)

      Logger.configure(level: previous_logger_level)

      assert log =~ "compiling storybook file: #{exs}"
    end
  end
end
