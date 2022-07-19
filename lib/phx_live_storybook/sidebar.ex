defmodule PhxLiveStorybook.Sidebar do
  @components_path Application.compile_env(:phx_live_storybook, :components_path)

  defmacro __using__(_) do
    [sidebar_tree_quote(@components_path) | folder_quotes(@components_path)]
  end

  defp sidebar_tree_quote(path) do
    tree = compile_tree(path)

    quote do
      def sidebar_tree() do
        unquote(tree)
      end
    end
  end

  defp compile_tree(path) do
    if File.dir?(path), do: recursive_scan(path)
  end

  defp recursive_scan(path) do
    for item <- path |> File.ls!() |> Enum.sort() do
      item_path = Path.join(path, item)

      sub_items =
        if File.dir?(item_path) do
          recursive_scan(item_path)
        else
          []
        end

      {item, sub_items}
    end
  end

  # generate @external_resource for all subfolders under lib/
  # to recompile when a file is created
  defp folder_quotes(path) do
    top_folders = "#{path}/*" |> Path.wildcard() |> Enum.filter(&File.dir?/1)
    sub_folders = "#{path}/**/*" |> Path.wildcard() |> Enum.filter(&File.dir?/1)

    for folder <- IO.inspect([path] ++ top_folders ++ sub_folders, label: "folders") do
      quote do
        @external_resource unquote(folder)
      end
    end
  end
end
