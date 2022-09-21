defmodule PhxLiveStorybook.StoryEntry do
  @moduledoc false
  defstruct [:path, :name, :icon]
end

defmodule PhxLiveStorybook.IndexEntry do
  @moduledoc false
  defstruct [:path, :folder_name, :folder_icon, :folder_open?, :entry]
end

defmodule PhxLiveStorybook.FolderEntry do
  @moduledoc false
  defstruct [:name, :entries, :path, :icon, open?: false]
end

# This module performs a recursive scan of all files/folders under :content_path
# and creates an in-memory tree hierarchy of content using above Story structs.
defmodule PhxLiveStorybook.Entries do
  @moduledoc false
  alias PhxLiveStorybook.ExsLoader
  alias PhxLiveStorybook.{FolderEntry, IndexEntry, StoryEntry}

  require Logger

  def story_file_suffix, do: ".story.exs"
  def index_file_suffix, do: ".index.exs"

  def content_tree(path, folders_config) do
    content_tree = if(path && File.dir?(path), do: recursive_scan(path, folders_config), else: [])
    [content_tree |> root_entry() |> maybe_apply_index()]
  end

  defp recursive_scan(path, folders_config, storybook_path \\ "") do
    for file_name <- path |> File.ls!() |> Enum.sort(:desc),
        file_path = Path.join(path, file_name),
        reduce: [] do
      acc ->
        cond do
          File.dir?(file_path) ->
            storybook_path = Path.join(["/", storybook_path, file_name])
            sub_entries = recursive_scan(file_path, folders_config, storybook_path)
            [folder_entry(file_name, storybook_path, sub_entries) |> maybe_apply_index() | acc]

          String.ends_with?(file_path, story_file_suffix()) ->
            [story_entry(file_path, storybook_path) | acc]

          String.ends_with?(file_path, index_file_suffix()) ->
            index_module = ExsLoader.load_exs(file_path, storybook_path, immediate: true)
            [index_entry(index_module, storybook_path) | acc]

          true ->
            acc
        end
    end
    |> sort_stories()
  end

  defp root_entry(content_tree) do
    %FolderEntry{
      entries: content_tree,
      path: "",
      name: "Storybook",
      icon: "fal fa-book-open"
    }
  end

  defp folder_entry(file_name, path, entries) do
    %FolderEntry{
      name: file_name |> String.capitalize() |> String.replace("_", " "),
      path: path,
      entries: entries
    }
  end

  defp story_entry(file_path, storybook_path) do
    %StoryEntry{
      path: Path.join(["/", storybook_path, story_file_name(file_path)]),
      name: story_name(file_path),
      icon: nil
    }
  end

  defp index_entry(module, path) do
    %IndexEntry{
      path: module_path(module, path),
      folder_name: module.folder_name(),
      folder_icon: module.folder_icon(),
      folder_open?: module.folder_open?(),
      entry: &module.entry/1
    }
  end

  defp maybe_apply_index(folder = %FolderEntry{entries: entries}) do
    groups = Enum.group_by(entries, &is_struct(&1, IndexEntry))
    index = Map.get(groups, true, [])
    other_entries = Map.get(groups, false, [])

    case index do
      [] ->
        folder

      [index | _] ->
        folder = if index.folder_name, do: %{folder | name: index.folder_name}, else: folder
        folder = if index.folder_icon, do: %{folder | icon: index.folder_icon}, else: folder
        folder = if index.folder_open?, do: %{folder | open?: index.folder_open?}, else: folder

        other_entries =
          for entry <- other_entries do
            if is_struct(entry, StoryEntry) do
              file_name = story_file_name(entry.path)

              try do
                opts = index.entry.(file_name)
                entry = if opts[:name], do: %{entry | name: opts[:name]}, else: entry
                entry = if opts[:icon], do: %{entry | icon: opts[:icon]}, else: entry
                entry
              rescue
                FunctionClauseError -> entry
              end
            else
              entry
            end
          end

        %{folder | entries: other_entries}
    end
  end

  defp story_file_name(file_path) do
    file_path |> Path.basename() |> String.replace_suffix(story_file_suffix(), "")
  end

  defp story_name(file_path) do
    file_path
    |> story_file_name()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp module_path(module, path) do
    module_name = module |> to_string() |> String.split(".") |> Enum.at(-1)
    Path.join(["/", path, Macro.underscore(module_name)])
  end

  @story_priority %{StoryEntry => 0, FolderEntry => 1}
  defp sort_stories(stories) do
    Enum.sort_by(stories, &Map.get(@story_priority, &1.__struct__))
  end

  def leaves(content_tree, acc \\ []) do
    Enum.flat_map(content_tree, fn entry ->
      case entry do
        %StoryEntry{} -> [entry | acc]
        %FolderEntry{entries: entries} -> leaves(entries, acc)
        %IndexEntry{} -> acc
      end
    end)
  end

  def flat_list(content_tree, acc \\ []) do
    Enum.flat_map(content_tree, fn entry ->
      case entry do
        %StoryEntry{} -> [entry | acc]
        %FolderEntry{entries: entries} -> [entry | flat_list(entries, acc)]
        %IndexEntry{} -> acc
      end
    end)
  end
end
