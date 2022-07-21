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

      def components_module_prefix do
        Keyword.get(unquote(opts), :components_module_prefix)
      end

      def css_path do
        Keyword.get(unquote(opts), :css_path)
      end

      def js_path do
        Keyword.get(unquote(opts), :js_path)
      end
    end
  end
end
