defmodule PhxLiveStorybook.Quotes.PageQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.PageStory

  @doc false
  def page_quotes(leave_stories, themes, caller_file) do
    page_quotes =
      for %PageStory{module: module, navigation: navigation} <- leave_stories,
          navigation = Enum.map(navigation, &elem(&1, 0)),
          navigation = if(navigation == [], do: [nil], else: navigation),
          tab <- navigation,
          {theme, _label} <- themes do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def render_page(unquote(module), %{tab: unquote(tab), theme: unquote(theme)}) do
            unquote(
              try do
                module.render(%{tab: tab, theme: theme}) |> to_raw_html()
              rescue
                _exception ->
                  reraise CompileError,
                          [
                            description:
                              "an error occured while rendering page tab #{inspect(tab)}",
                            file: caller_file
                          ],
                          __STACKTRACE__
              end
            )
          end
        end
      end

    if Enum.any?(page_quotes) do
      page_quotes
    else
      [
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def render_page(module, assigns) do
            raise "no page has been defined yet in this storybook"
          end
        end
      ]
    end
  end

  defp to_raw_html(heex) do
    heex
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end
end
