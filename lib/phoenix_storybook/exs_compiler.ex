defmodule PhoenixStorybook.ExsCompiler do
  @moduledoc false

  # This module is intended to compile exs files non concurrently.
  # We indeed use `Code.put_compiler_option/2` which can lead to race conditions.

  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(opts), do: {:ok, opts}

  def compile_exs!(path, relative_to) do
    do_compile_exs!(path, relative_to)
  end

  def compile_exs(path, relative_to) do
    GenServer.call(__MODULE__, {:compile_exs, path, relative_to})
  end

  def handle_call({:compile_exs, path, relative_to}, _from, state) do
    module = do_compile_exs(path, relative_to)
    {:reply, module, state}
  end

  defp do_compile_exs!(path, relative_to) do
    Logger.debug("compiling storybook file: #{path}")
    Code.put_compiler_option(:ignore_module_conflict, true)
    modules = Code.compile_file(path, relative_to) |> Enum.map(&elem(&1, 0))

    Enum.find(
      modules,
      Enum.at(modules, 0),
      &function_exported?(&1, :storybook_type, 0)
    )
  after
    Code.put_compiler_option(:ignore_module_conflict, false)
  end

  defp do_compile_exs(path, relative_to) do
    module = do_compile_exs!(path, relative_to)
    {:ok, module}
  rescue
    e ->
      message = "Could not compile #{inspect(path)}"
      exception = Exception.format(:error, e, __STACKTRACE__)
      Logger.error(message <> "\n\n" <> exception)
      {:error, message, exception}
  end
end
