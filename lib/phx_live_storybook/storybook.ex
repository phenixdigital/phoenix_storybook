defmodule PhxLiveStorybook.Storybook do
  defmacro __using__(_) do
    quote do
      alias PhxLiveStorybook.StorybookEntries

      @components_path Application.compile_env(:phx_live_storybook, :components_path)
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
end
