defmodule PhxLiveStorybook.ComponentEntry do
  defstruct [:name, :module, :path, :module_name]
end

defmodule PhxLiveStorybook.FolderEntry do
  defstruct [:name, :sub_entries]
end

defmodule PhxLiveStorybook.StorybookEntries do
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  def quotes(opts) do
    quote bind_quoted: [opts: opts] do
      alias PhxLiveStorybook.StorybookEntries

      @backend_module __MODULE__
      @otp_app Keyword.get(opts, :otp_app)
      @components_path Application.compile_env(@otp_app, @backend_module, []) |> Keyword.get(:components_path)
      @components_pattern if @components_path, do: "#{@components_path}/**/*"
      @paths if @components_path, do: Path.wildcard(@components_pattern), else: []
      @paths_hash :erlang.md5(@paths)
      @entries StorybookEntries.entries(@components_path)

      # this file should be recompiled whenever any of the component file is touched
      for path <- @paths do
        @external_resource path
      end

      # this file should be recompiled whenever any file has been created or deleted
      def __mix_recompile__?() do
        if @components_pattern do
          @components_pattern |> Path.wildcard() |> :erlang.md5() !=
            @paths_hash
        else
          false
        end
      end

      # at compile time, build a tree of all files under the watched component folder
      def storybook_entries, do: @entries
    end
  end

  def entries(path) do
    if path && File.dir?(path) do
      recursive_scan(path)
    else
      []
    end
  end

  defp recursive_scan(path) do
    for file_name <- path |> File.ls!() |> Enum.sort(:desc),
        file_path = Path.join(path, file_name),
        reduce: [] do
      acc ->
        if File.dir?(file_path) do
          [%FolderEntry{name: file_name, sub_entries: recursive_scan(file_path)} | acc]
        else
          entry_module = entry_module(file_path)
          case entry_type(entry_module) do
            nil -> acc
            :component -> [component_entry(file_path, entry_module) | acc]
          end
        end
    end
  end

  defp component_entry(path, module) do
    %ComponentEntry{
      module: module,
      path: path,
      module_name: module |> to_string() |> String.split(".") |> Enum.at(-1),
      name: apply(module, :public_name, [])
    }
  end

  defp entry_module(entry_path) do
    {:ok, contents} = File.read(entry_path)

    case Regex.run(~r/defmodule\s+([^\s]+)\s+do/, contents, capture: :all_but_first) do
      nil -> nil
      [module_name] -> String.to_atom("Elixir.#{module_name}")
    end
  end

  defp entry_type(entry_module) do
    fun = :storybook_type
    Code.ensure_compiled(entry_module)

    if Kernel.function_exported?(entry_module, fun, 0) do
      apply(entry_module, fun, [])
    else
      nil
    end
  end
end
