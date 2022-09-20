defmodule PhxLiveStorybook.BackendBehaviour do
  @moduledoc """
  Behaviour implemented by your backend module.
  """

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  @doc """
  Returns a configuration value from your config.exs storybook settings.

  `key` is the config key
  `default` is an optional default value if no value can be fetched.
  """
  @callback config(key :: atom(), default :: any()) :: any()

  @doc """
  Returns a precompiled tree of your storybook stories.
  """
  @callback content_tree() :: [%ComponentEntry{} | %FolderEntry{} | %PageEntry{}]

  @doc """
  Returns all the leaves of the storybook content tree (ie. all stories that are
  not a folder)
  """
  @callback leaves() :: [%ComponentEntry{} | %PageEntry{}]

  @doc """
  Returns all the notes of the storybook content tree as a flat list.
  """
  @callback flat_list() :: [%ComponentEntry{} | %PageEntry{}]

  @doc """
  Returns a story from its absolute path.
  """
  @callback find_entry_by_path(String.t()) :: %ComponentEntry{} | %FolderEntry{} | %PageEntry{}

  @doc """
  Returns the storybook path of any story, from its module.
  """
  @callback story_path(atom()) :: String.t()
end

defmodule PhxLiveStorybook do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias PhxLiveStorybook.Entries
  alias PhxLiveStorybook.StoryValidator

  require Logger

  @doc false
  defmacro __using__(opts) do
    {opts, _} = Code.eval_quoted(opts, [], __CALLER__)

    [
      behaviour_quote(),
      recompilation_quotes(opts),
      config_quotes(opts),
      stories_quotes(opts)
    ]
  end

  defp behaviour_quote do
    quote do
      @behaviour PhxLiveStorybook.BackendBehaviour
    end
  end

  # This quote triggers recompilation for the module whenever a new file or any index file under
  # content_path has been touched.
  defp recompilation_quotes(opts) do
    content_path = Keyword.get(opts, :content_path)
    components_pattern = if content_path, do: "#{content_path}/**/*"

    quote do
      @paths if unquote(content_path), do: Path.wildcard(unquote(components_pattern)), else: []
      @paths_hash :erlang.md5(@paths)

      def __mix_recompile__? do
        if unquote(components_pattern) do
          unquote(components_pattern) |> Path.wildcard() |> :erlang.md5() !=
            @paths_hash
        else
          false
        end
      end
    end
  end

  @doc false
  defp stories_quotes(opts) do
    content_path = Keyword.get(opts, :content_path)
    content_tree = content_tree(opts)
    entries = Entries.flat_list(content_tree)
    leaves = Entries.leaves(content_tree)

    find_entry_by_path_quotes =
      for entry <- entries do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def find_entry_by_path(unquote(entry.storybook_path)) do
            unquote(Macro.escape(entry))
          end
        end
      end

    story_path_quotes =
      for entry <- leaves do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def story_path(unquote(entry.module)) do
            unquote(
              entry.storybook_path
              |> String.replace_prefix(content_path, "")
              |> String.replace_prefix("/", "")
              |> String.replace_suffix(Entries.story_file_suffix(), "")
            )
          end
        end
      end

    single_quote =
      quote do
        def load_story(story_path) do
          content_path = Keyword.get(unquote(opts), :content_path)
          story_path = String.replace_prefix(story_path, "/", "")

          story_path =
            if String.ends_with?(story_path, Entries.story_file_suffix()) do
              story_path
            else
              story_path <> Entries.story_file_suffix()
            end

          try do
            Code.put_compiler_option(:ignore_module_conflict, true)
            [{story_module, _} | _] = Code.compile_file(story_path, content_path)
            StoryValidator.validate!(story_module)
          rescue
            e in Code.LoadError ->
              Logger.bare_log(:warning, "could not load story #{inspect(story_path)}")
              Logger.bare_log(:warning, inspect(e))
              nil
          after
            Code.put_compiler_option(:ignore_module_conflict, false)
          end
        end

        @impl PhxLiveStorybook.BackendBehaviour
        def find_entry_by_path(_), do: nil

        @impl PhxLiveStorybook.BackendBehaviour
        def story_path(_), do: nil

        @impl PhxLiveStorybook.BackendBehaviour
        def content_tree, do: unquote(Macro.escape(content_tree))

        @impl PhxLiveStorybook.BackendBehaviour
        def leaves, do: unquote(Macro.escape(Entries.leaves(leaves)))

        @impl PhxLiveStorybook.BackendBehaviour
        def flat_list, do: unquote(Macro.escape(entries))
      end

    find_entry_by_path_quotes ++ story_path_quotes ++ [single_quote]
  end

  @doc false
  defp config_quotes(opts) do
    quote do
      @impl PhxLiveStorybook.BackendBehaviour
      def config(key, default \\ nil) do
        Keyword.get(unquote(opts), key, default)
      end
    end
  end

  defp content_tree(opts) do
    content_path = Keyword.get(opts, :content_path)
    folders_config = Keyword.get(opts, :folders, [])
    Entries.content_tree(content_path, folders_config)
  end
end
