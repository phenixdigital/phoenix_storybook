defmodule PhxLiveStorybook.ComponentEntry do
  @moduledoc false
  defstruct [
    :module,
    :path,
    :absolute_path,
    :type,
    :name,
    :module_name,
    :description,
    :function,
    :component,
    :variations,
    :icon
  ]
end

defmodule PhxLiveStorybook.PageEntry do
  @moduledoc false
  defstruct [
    :name,
    :description,
    :module,
    :path,
    :module_name,
    :absolute_path,
    :icon,
    :navigation
  ]
end

defmodule PhxLiveStorybook.FolderEntry do
  @moduledoc false
  defstruct [:name, :nice_name, :sub_entries, :absolute_path, :icon]
end

# This module performs a recursive scan of all files/folders under :content_path
# and creates an in-memory tree hierarchy of content using above Entry structs.
defmodule PhxLiveStorybook.Entries do
  @moduledoc false
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  @doc false
  def entries(path, folders_config) do
    if path && File.dir?(path) do
      recursive_scan(path, folders_config)
    else
      []
    end
  end

  defp recursive_scan(path, folders_config, absolute_path \\ "") do
    for file_name <- path |> File.ls!() |> Enum.sort(:desc),
        file_path = Path.join(path, file_name),
        reduce: [] do
      acc ->
        cond do
          File.dir?(file_path) ->
            absolute_path = "#{absolute_path}/#{file_name}"
            folder_config = Keyword.get(folders_config, String.to_atom(absolute_path), [])

            [
              folder_entry(
                file_name,
                folder_config,
                absolute_path,
                recursive_scan(file_path, folders_config, absolute_path)
              )
              | acc
            ]

          Path.extname(file_path) == ".exs" ->
            entry_module = entry_module(file_path)

            unless Code.ensure_loaded?(entry_module) do
              Code.eval_file(file_path)
            end

            case entry_type(entry_module) do
              nil ->
                acc

              type when type in [:component, :live_component] ->
                [component_entry(file_path, entry_module, absolute_path) | acc]

              :page ->
                [page_entry(file_path, entry_module, absolute_path) | acc]
            end

          true ->
            acc
        end
    end
    |> sort_entries()
  end

  defp folder_entry(file_name, folder_config, absolute_path, sub_entries) do
    %FolderEntry{
      name: file_name,
      nice_name:
        Keyword.get_lazy(folder_config, :name, fn ->
          file_name |> String.capitalize() |> String.replace("_", " ")
        end),
      absolute_path: absolute_path,
      sub_entries: sub_entries,
      icon: folder_config[:icon]
    }
  end

  defp component_entry(path, module, absolute_path) do
    module_name = module |> to_string() |> String.split(".") |> Enum.at(-1)

    %ComponentEntry{
      module: module,
      type: module.storybook_type(),
      path: path,
      absolute_path: "#{absolute_path}/#{Macro.underscore(module_name)}",
      name: module.name(),
      module_name: module_name,
      description: module.description(),
      component: call_if_exported(module, :component),
      function: call_if_exported(module, :function),
      variations: module.variations(),
      icon: module.icon()
    }
  end

  defp page_entry(path, module, absolute_path) do
    module_name = module |> to_string() |> String.split(".") |> Enum.at(-1)

    %PageEntry{
      module: module,
      path: path,
      absolute_path: "#{absolute_path}/#{Macro.underscore(module_name)}",
      module_name: module_name,
      name: module.name(),
      description: module.description(),
      navigation: module.navigation(),
      icon: module.icon()
    }
  end

  defp call_if_exported(mod, fun) do
    if function_exported?(mod, fun, 0), do: apply(mod, fun, []), else: nil
  end

  @entry_priority %{PageEntry => 0, ComponentEntry => 1, FolderEntry => 2}
  defp sort_entries(entries) do
    Enum.sort_by(entries, &Map.get(@entry_priority, &1.__struct__))
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

    if Kernel.function_exported?(entry_module, fun, 0) do
      apply(entry_module, fun, [])
    else
      nil
    end
  end

  def all_leaves(entries, acc \\ []) do
    Enum.flat_map(entries, fn entry ->
      case entry do
        %ComponentEntry{} -> [entry | acc]
        %PageEntry{} -> [entry | acc]
        %FolderEntry{sub_entries: sub_entries} -> all_leaves(sub_entries, acc)
      end
    end)
  end

  def flat_list(entries, acc \\ []) do
    Enum.flat_map(entries, fn entry ->
      case entry do
        %ComponentEntry{} -> [entry | acc]
        %PageEntry{} -> [entry | acc]
        %FolderEntry{sub_entries: sub_entries} -> [entry | flat_list(sub_entries, acc)]
      end
    end)
  end
end
