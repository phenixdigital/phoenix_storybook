defmodule PhxLiveStorybook.Quotes.SourceQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentStory
  alias PhxLiveStorybook.Rendering.CodeRenderer

  @doc false
  def source_quotes(leave_stories) do
    quotes =
      for %ComponentStory{module: module} <- leave_stories do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def render_source(unquote(module)) do
            unquote(CodeRenderer.render_component_source(module) |> to_raw_html())
          end
        end
      end

    default_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def render_source(module) do
          raise "unknown module #{inspect(module)}"
        end
      end

    quotes ++ [default_quote]
  end

  defp to_raw_html(heex) do
    heex
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end
end
