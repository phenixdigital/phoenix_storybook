defmodule PhxLiveStorybook.StorybookEntries do
  def entries(path) do
    if path && File.dir?(path) do
      recursive_scan(path)
    end
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
end
