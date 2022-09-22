defmodule PhxLiveStorybook.ExsCompiler do
  @moduledoc false

  # This module is intended to compile exs files non concurrently.
  # We indeed use `Code.put_compiler_option/2` which can lead to race conditions.
  # Default behavior can be disabled with the `immediate: true` option.

  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(opts), do: {:ok, opts}

  def compile_exs(path, relative_to, opts \\ [])

  def compile_exs(path, relative_to, immediate: true), do: do_compile_exs(path, relative_to)

  def compile_exs(path, relative_to, _opts) do
    GenServer.call(__MODULE__, {:compile_exs, path, relative_to})
  end

  def handle_call({:compile_exs, path, relative_to}, _from, state) do
    module = do_compile_exs(path, relative_to)
    {:reply, module, state}
  end

  defp do_compile_exs(path, relative_to) do
    Logger.debug("compiling storybook file: #{path}")
    Code.put_compiler_option(:ignore_module_conflict, true)
    [{module, _} | _] = Code.compile_file(path, relative_to)
    module
  rescue
    e ->
      Logger.error("""
      could not compile #{inspect(path)}:

      #{Exception.format(:error, e, __STACKTRACE__)}
      """)

      nil
  after
    Code.put_compiler_option(:ignore_module_conflict, false)
  end
end
