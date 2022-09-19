defmodule PhxLiveStorybook.Quotes.StoriesQuotes do
  @moduledoc false

  alias PhxLiveStorybook.Stories

  @doc false
  # This quote inlines a stories/0 function to return the content
  # tree of current storybook.
  def stories_quotes(stories) do
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
