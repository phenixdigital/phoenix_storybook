defmodule PhxLiveStorybook.BackendBehaviour do
  @moduledoc """
  Behaviour implemented by your backend module.
  """

  alias PhxLiveStorybook.{FolderEntry, StoryEntry}

  @doc """
  Returns a configuration value from your config.exs storybook settings.

  `key` is the config key
  `default` is an optional default value if no value can be fetched.
  """
  @callback config(key :: atom(), default :: any()) :: any()

  @doc """
  Returns a precompiled tree of your storybook stories.
  """
  @callback content_tree() :: [%FolderEntry{} | %StoryEntry{}]

  @doc """
  Returns all the leaves (only stories) of the storybook content tree.
  """
  @callback leaves() :: [%StoryEntry{}]

  @doc """
  Returns all the nodes (stoires & folders) of the storybook content tree as a flat list.
  """
  @callback flat_list() :: [%FolderEntry{} | %StoryEntry{}]

  @doc """
  Returns an entry from its absolute storybook path (not filesystem).
  """
  @callback find_entry_by_path(String.t()) :: %FolderEntry{} | %StoryEntry{}

  @doc """
  Retuns a storybook path from a story module.
  """
  @callback storybook_path(atom()) :: String.t()
end

defmodule PhxLiveStorybook do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias PhxLiveStorybook.Entries
  alias PhxLiveStorybook.ExsCompiler
  alias PhxLiveStorybook.Stories.StoryValidator

  require Logger

  @doc false
  defmacro __using__(opts) do
    {opts, _} = Code.eval_quoted(opts, [], __CALLER__)
    opts = merge_opts_and_config(opts, __CALLER__.module)
    content_tree = content_tree(opts)

    [
      main_quote(opts),
      recompilation_quotes(opts),
      story_compilation_quotes(opts, content_tree),
      config_quotes(opts),
      stories_quotes(opts, content_tree)
    ]
  end

  defp merge_opts_and_config(opts, backend_module) do
    config_opts = Application.get_env(opts[:otp_app], backend_module, [])
    Keyword.merge(opts, config_opts)
  end

  defp main_quote(opts) do
    quote do
      @behaviour PhxLiveStorybook.BackendBehaviour

      @impl PhxLiveStorybook.BackendBehaviour
      def storybook_path(story_module) do
        if Code.ensure_loaded?(story_module) do
          content_path = Keyword.get(unquote(opts), :content_path)

          file_path =
            story_module.__file_path__()
            |> String.replace_prefix(content_path, "")
            |> String.replace_suffix(Entries.story_file_suffix(), "")
        end
      end
    end
  end

  defp story_compilation_quotes(opts, content_tree) do
    content_path = Keyword.get(opts, :content_path)

    case compilation_mode(opts) do
      :lazy ->
        quote do
          def load_story(story_path) do
            story_path = String.replace_prefix(story_path, "/", "")
            story_path = story_path <> Entries.story_file_suffix()

            case ExsCompiler.compile_exs(story_path, unquote(content_path)) do
              {:ok, story} -> StoryValidator.validate(story)
              {:error, message, exception} -> {:error, message, exception}
            end
          end
        end

      :eager ->
        quotes =
          for story_entry <- Entries.leaves(content_tree) do
            story_name = String.replace_prefix(story_entry.path, "/", "")
            story_path = story_name <> Entries.story_file_suffix()

            story =
              story_path
              |> ExsCompiler.compile_exs!(content_path)
              |> StoryValidator.validate!()

            quote do
              @external_resource Path.join(unquote(content_path), unquote(story_path))
              def load_story(unquote(story_name)) do
                {:ok, unquote(story)}
              end
            end
          end

        quotes ++
          [
            quote do
              def load_story(_), do: {:error, :not_found}
            end
          ]
    end
  end

  # This quote triggers recompilation for the module whenever a new file or any index file under
  # content_path has been touched.
  defp recompilation_quotes(opts) do
    content_path =
      Keyword.get_lazy(opts, :content_path, fn -> raise "content_path key must be set" end)

    components_pattern = Path.join(content_path, "**/*")
    index_pattern = Path.join(content_path, "**/*#{Entries.index_file_suffix()}")

    quote do
      @index_paths Path.wildcard(unquote(index_pattern))
      @paths Path.wildcard(unquote(components_pattern))
      @paths_hash :erlang.md5(@paths)

      for index_path <- @index_paths do
        @external_resource index_path
      end

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
  defp stories_quotes(_opts, content_tree) do
    entries = Entries.flat_list(content_tree)
    leaves = Entries.leaves(content_tree)

    find_entry_by_path_quotes =
      for entry <- entries do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def find_entry_by_path(unquote(entry.path)) do
            unquote(Macro.escape(entry))
          end
        end
      end

    single_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def find_entry_by_path(_), do: nil

        @impl PhxLiveStorybook.BackendBehaviour
        def content_tree, do: unquote(Macro.escape(content_tree))

        @impl PhxLiveStorybook.BackendBehaviour
        def leaves, do: unquote(Macro.escape(Entries.leaves(leaves)))

        @impl PhxLiveStorybook.BackendBehaviour
        def flat_list, do: unquote(Macro.escape(entries))
      end

    find_entry_by_path_quotes ++ [single_quote]
  end

  defp content_tree(opts) do
    content_path = Keyword.get(opts, :content_path)
    folders_config = Keyword.get(opts, :folders, [])
    Entries.content_tree(content_path, folders_config)
  end

  defp compilation_mode(opts) do
    case Keyword.get(opts, :compilation_mode) do
      mode when mode in [:lazy, :eager] ->
        mode

      _ ->
        if Code.ensure_loaded?(Mix) and Mix.env() == :dev do
          :lazy
        else
          :eager
        end
    end
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
end
