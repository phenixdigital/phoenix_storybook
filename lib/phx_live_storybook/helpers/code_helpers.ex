defmodule PhxLiveStorybook.CodeHelpers do
  @moduledoc false

  def load_exs(path, relative_to) do
    Code.put_compiler_option(:ignore_module_conflict, true)
    [{module, _} | _] = Code.compile_file(path, relative_to)
    module
  rescue
    e in Code.LoadError ->
      Logger.bare_log(:warning, "could not load #{inspect(path)}")
      Logger.bare_log(:warning, inspect(e))
      nil

    e in CompileError ->
      Logger.bare_log(:warning, "could not compile #{inspect(path)}")
      Logger.bare_log(:warning, inspect(e))
      nil
  after
    Code.put_compiler_option(:ignore_module_conflict, false)
  end
end
