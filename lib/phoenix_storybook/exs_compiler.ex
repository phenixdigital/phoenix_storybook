defmodule PhoenixStorybook.ExsCompiler do
  @moduledoc false

  # This module is intended to compile exs files non concurrently.
  # We indeed use `Code.put_compiler_option/2` which can lead to race conditions.

  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(opts), do: {:ok, opts}

  def compile_exs!(path, relative_to, opts \\ []) do
    do_compile_exs!(path, relative_to, opts)
  end

  def compile_exs(path, relative_to, opts \\ []) do
    GenServer.call(__MODULE__, {:compile_exs, path, relative_to, opts})
  end

  def handle_call({:compile_exs, path, relative_to, opts}, _from, state) do
    module = do_compile_exs(path, relative_to, opts)
    {:reply, module, state}
  end

  defp do_compile_exs!(path, relative_to, opts) do
    original_ignore_module_conflict = Code.get_compiler_option(:ignore_module_conflict)

    try do
      if opts[:compilation_debug] do
        Logger.debug("compiling storybook file: #{path}")
      end

      Code.put_compiler_option(:ignore_module_conflict, true)
      modules = Code.compile_file(path, relative_to) |> Enum.map(&elem(&1, 0))

      Enum.find(
        modules,
        Enum.at(modules, 0),
        fn module ->
          Code.ensure_compiled!(module)
          function_exported?(module, :storybook_type, 0)
        end
      )
    after
      Code.put_compiler_option(:ignore_module_conflict, original_ignore_module_conflict)
    end
  end

  defp do_compile_exs(path, relative_to, opts) do
    module = do_compile_exs!(path, relative_to, opts)
    {:ok, module}
  rescue
    e ->
      message = "Could not compile #{inspect(path)}"
      exception = Exception.format(:error, e, __STACKTRACE__)
      Logger.error(message <> "\n\n" <> exception)
      {:error, message, exception}
  end
end
