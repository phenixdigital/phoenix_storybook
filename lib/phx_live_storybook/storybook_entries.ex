defmodule PhxLiveStorybook.StorybookEntries do
  def quotes(opts) do
    quote bind_quoted: [opts: opts] do
      alias PhxLiveStorybook.StorybookEntries

      @components_path Keyword.get(opts, :components_path)
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
    for entry_file_name <- path |> File.ls!() |> Enum.sort() do
      entry_path = Path.join(path, entry_file_name)

      if File.dir?(entry_path) do
        sub_entries = recursive_scan(entry_path)
        {:folder, entry_file_name, sub_entries}
      else
        entry_module = entry_module(entry_path)

        case entry_type(entry_module) do
          nil ->
            nil

          :component ->
            {:component,
             %{
               module: entry_module,
               path: entry_path,
               module_name: entry_module |> to_string() |> String.split(".") |> Enum.at(-1),
               name: apply(entry_module, :public_name, [])
             }}
        end
      end
    end
    |> Enum.reject(&is_nil/1)
  end

  def entry_module(entry_path) do
    {:ok, contents} = File.read(entry_path)

    case Regex.run(~r/defmodule\s+([^\s]+)\s+do/, contents, capture: :all_but_first) do
      nil -> nil
      [module_name] -> String.to_atom("Elixir.#{module_name}")
    end
  end

  def entry_type(entry_module) do
    fun = :storybook_type
    Code.ensure_loaded(entry_module)

    if Kernel.function_exported?(entry_module, fun, 0) do
      apply(entry_module, fun, [])
    else
      nil
    end
  end
end
