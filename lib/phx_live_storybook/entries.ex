defmodule PhxLiveStorybook.ComponentEntry do
  @moduledoc false
  defstruct [:name, :module, :path, :module_name, :absolute_path]
end

defmodule PhxLiveStorybook.PageEntry do
  @moduledoc false
  defstruct [:name, :module, :path, :module_name, :absolute_path]
end

defmodule PhxLiveStorybook.FolderEntry do
  @moduledoc false
  defstruct [:name, :nice_name, :sub_entries, :absolute_path, :icon]
end

defmodule PhxLiveStorybook.Entries do
  @moduledoc false
  alias PhxLiveStorybook.{ComponentEntry, Entries, FolderEntry, PageEntry}

  @doc false
  # This quote inlines a entries/0 function to return the content
  # tree of current storybook.
  def entries_quote(backend_module, opts) do
    otp_app = Keyword.get(opts, :otp_app)
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    folders_config = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:folders)
    entries = Entries.entries(content_path, folders_config)
    all_leaves = Entries.all_leaves(entries)

    loop_quotes =
      for entry <- Entries.flat_list(entries) do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def find_entry_by_path(unquote(entry.absolute_path)) do
            unquote(Macro.escape(entry))
          end
        end
      end

    single_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def find_entry_by_path(_), do: nil

        @impl PhxLiveStorybook.BackendBehaviour
        def entries, do: unquote(Macro.escape(entries))

        @impl PhxLiveStorybook.BackendBehaviour
        def all_leaves, do: unquote(Macro.escape(all_leaves))
      end

    loop_quotes ++ [single_quote]
  end

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
        if File.dir?(file_path) do
          absolute_path = "#{absolute_path}/#{file_name}"
          folder_config = Keyword.get(folders_config, String.to_atom(absolute_path), [])

          [
            %FolderEntry{
              name: file_name,
              nice_name:
                Keyword.get_lazy(folder_config, :name, fn ->
                  file_name |> String.capitalize() |> String.replace("_", " ")
                end),
              absolute_path: absolute_path,
              sub_entries: recursive_scan(file_path, folders_config, absolute_path),
              icon: folder_config[:icon]
            }
            | acc
          ]
        else
          entry_module = entry_module(file_path)

          case entry_type(entry_module) do
            nil ->
              acc

            type when type in [:component, :live_component] ->
              [component_entry(file_path, entry_module, absolute_path) | acc]

            :page ->
              [page_entry(file_path, entry_module, absolute_path) | acc]
          end
        end
    end
    |> sort_entries()
  end

  @entry_priority %{PageEntry => 0, ComponentEntry => 1, FolderEntry => 2}
  defp sort_entries(entries) do
    Enum.sort_by(entries, &Map.get(@entry_priority, &1.__struct__))
  end

  defp component_entry(path, module, absolute_path) do
    module_name = module |> to_string() |> String.split(".") |> Enum.at(-1)

    %ComponentEntry{
      module: module,
      path: path,
      module_name: module_name,
      name: module.name(),
      absolute_path: "#{absolute_path}/#{Macro.underscore(module_name)}"
    }
  end

  defp page_entry(path, module, absolute_path) do
    module_name = module |> to_string() |> String.split(".") |> Enum.at(-1)

    %PageEntry{
      module: module,
      path: path,
      module_name: module_name,
      name: module.name(),
      absolute_path: "#{absolute_path}/#{Macro.underscore(module_name)}"
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
