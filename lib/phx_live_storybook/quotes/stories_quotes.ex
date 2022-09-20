defmodule PhxLiveStorybook.Quotes.StoriesQuotes do
  @moduledoc false

  alias PhxLiveStorybook.Stories
  alias PhxLiveStorybook.StoryValidator

  require Logger

  @doc false
  # This quote inlines a stories/0 function to return the content
  # tree of current storybook.
  def stories_quotes(opts, stories) do
    flat_list = Stories.flat_list(stories)

    find_story_by_path_quotes =
      for story <- flat_list do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def find_story_by_path(unquote(story.storybook_path)) do
            unquote(Macro.escape(story))
          end
        end
      end

    single_quote =
      quote do
        def story_file_suffix, do: ".story.exs"

        def load_story(story_path) do
          content_path = Keyword.get(unquote(opts), :content_path)
          story_path = String.replace_prefix(story_path, "/", "")

          story_path =
            if String.ends_with?(story_path, story_file_suffix()) do
              story_path
            else
              story_path <> story_file_suffix()
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

        def story_path(story_module) do
          content_path = Keyword.get(unquote(opts), :content_path)

          story_module.__info__(:compile)[:source]
          |> to_string()
          |> String.replace_prefix(content_path, "")
          |> String.replace_prefix("/", "")
          |> String.replace_suffix(story_file_suffix(), "")
        end

        @impl PhxLiveStorybook.BackendBehaviour
        def find_story_by_path(_), do: nil

        @impl PhxLiveStorybook.BackendBehaviour
        def stories, do: unquote(Macro.escape(stories))

        @impl PhxLiveStorybook.BackendBehaviour
        def all_leaves, do: unquote(Macro.escape(Stories.all_leaves(stories)))

        @impl PhxLiveStorybook.BackendBehaviour
        def flat_list, do: unquote(Macro.escape(flat_list))
      end

    find_story_by_path_quotes ++ [single_quote]
  end
end
