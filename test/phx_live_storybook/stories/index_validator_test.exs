defmodule PhxLiveStorybook.Stories.IndexValidatorTest do
  use ExUnit.Case, async: true

  setup do
    [path: Path.expand("../../fixtures/indexes", __DIR__)]
  end

  test "with valid index it wont raise", %{path: path} do
    Code.compile_file("valid.index.exs", path)
  end

  test "with empty index it wont raise", %{path: path} do
    Code.compile_file("empty.index.exs", path)
  end

  test "with bad folder_icon it will raise", %{path: path} do
    assert_raise CompileError, ~r/icon must be a tuple 2, 3 or 4 items/, fn ->
      Code.compile_file("bad_folder_icon.index.exs", path)
    end
  end

  test "with bad folder_name it will raise", %{path: path} do
    assert_raise CompileError, ~r/folder_name must return a binary/, fn ->
      Code.compile_file("bad_folder_name.index.exs", path)
    end
  end

  test "with bad entry it will raise", %{path: path} do
    assert_raise CompileError, ~r/entry\("colors"\) icon is invalid/, fn ->
      Code.compile_file("bad_entry.index.exs", path)
    end
  end

  test "with bad entry icon it will raise", %{path: path} do
    assert_raise CompileError, ~r/icon provider must be either :fa or :hero/, fn ->
      Code.compile_file("bad_entry_icon_provider.index.exs", path)
    end
  end
end
