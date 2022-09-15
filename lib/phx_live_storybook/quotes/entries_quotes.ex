defmodule PhxLiveStorybook.Quotes.EntriesQuotes do
  @moduledoc false

  alias PhxLiveStorybook.Entries

  @doc false
  # This quote inlines a entries/0 function to return the content
  # tree of current storybook.
  def entries_quotes(entries) do
    flat_list = Entries.flat_list(entries)

    find_entry_by_path_quotes =
      for entry <- flat_list do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def find_entry_by_path(unquote(entry.storybook_path)) do
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
        def all_leaves, do: unquote(Macro.escape(Entries.all_leaves(entries)))

        @impl PhxLiveStorybook.BackendBehaviour
        def flat_list, do: unquote(Macro.escape(flat_list))
      end

    find_entry_by_path_quotes ++ [single_quote]
  end
end
