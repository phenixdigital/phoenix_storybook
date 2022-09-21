defmodule PhxLiveStorybook.ExsLoader do
  @moduledoc false
  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(opts), do: {:ok, opts}

  def load_exs(path, relative_to, opts \\ [])

  def load_exs(path, relative_to, immediate: true), do: do_load_exs(path, relative_to)

  def load_exs(path, relative_to, _opts) do
    GenServer.call(__MODULE__, {:load_exs, path, relative_to})
  end

  def handle_call({:load_exs, path, relative_to}, _from, state) do
    module = do_load_exs(path, relative_to)
    {:reply, module, state}
  end

  defp do_load_exs(path, relative_to) do
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
