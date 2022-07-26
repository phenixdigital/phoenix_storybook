defmodule PhxLiveStorybook.ComponentEntry do
  @moduledoc false
  defstruct [:name, :module, :path, :module_name]
end

defmodule PhxLiveStorybook.FolderEntry do
  @moduledoc false
  defstruct [:name, :sub_entries]
end

defmodule PhxLiveStorybook.Entries do
  @moduledoc false
  alias PhxLiveStorybook.{ComponentEntry, Entries, FolderEntry}

  @doc false
  # This quote inlines a storybook_entries/0 function to return the content
  # tree of current storybook.
  def entries_quote(backend_module, opts) do
    otp_app = Keyword.get(opts, :otp_app)
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    entries = Entries.entries(content_path)
    path_to_first_leaf_entry = Entries.path_to_first_leaf(entries)

    quote do
      def storybook_entries, do: unquote(Macro.escape(entries))
      def path_to_first_leaf_entry, do: unquote(Macro.escape(path_to_first_leaf_entry))
    end
  end

  @doc false
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
          [
            %FolderEntry{
              name: file_name,
              sub_entries: file_path |> recursive_scan()
            }
            | acc
          ]
        else
          entry_module = entry_module(file_path)

          case entry_type(entry_module) do
            nil ->
              acc

            type when type in [:component, :live_component] ->
              [component_entry(file_path, entry_module) | acc]
          end
        end
    end
    |> sort_entries()
  end

  @entry_priority %{ComponentEntry => 0, FolderEntry => 1}
  defp sort_entries(entries) do
    Enum.sort_by(entries, &Map.get(@entry_priority, &1.__struct__))
  end

  defp component_entry(path, module) do
    %ComponentEntry{
      module: module,
      path: path,
      module_name: module |> to_string() |> String.split(".") |> Enum.at(-1),
      name: apply(module, :name, [])
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

  def path_to_first_leaf(entries) do
    case path_to_first_leaf(entries, []) do
      nil ->
        nil

      entries ->
        entries
        |> Enum.reverse()
        |> Enum.map(fn
          %FolderEntry{name: name} -> name
          %ComponentEntry{path: path} -> Path.basename(path, ".ex")
        end)
    end
  end

  def path_to_first_leaf(entries, acc) do
    Enum.find_value(entries, fn entry ->
      case entry do
        %ComponentEntry{} ->
          [entry | acc]

        %FolderEntry{sub_entries: sub_entries} ->
          path_to_first_leaf(sub_entries, [entry | acc])
      end
    end)
  end
end
