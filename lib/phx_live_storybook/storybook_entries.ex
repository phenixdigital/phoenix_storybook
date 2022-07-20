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
    for entry <- path |> File.ls!() |> Enum.sort() do
      entry_path = Path.join(path, entry)

      if File.dir?(entry_path) do
        sub_entries = recursive_scan(entry_path)
        {:folder, entry, sub_entries}
      else
        {:file, entry}
      end
    end
  end
end
