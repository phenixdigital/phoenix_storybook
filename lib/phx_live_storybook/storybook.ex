defmodule PhxLiveStorybook.Storybook do
  alias PhxLiveStorybook.StorybookEntries

  defmacro __using__(opts) do
    [quotes(opts), StorybookEntries.quotes(opts)]
  end

  def quotes(opts) do
    quote do
      def storybook_title do
        Keyword.get(unquote(opts), :title, "Live Storybook")
      end
    end
  end
end
