defmodule PhxLiveStorybook.Quotes.SourceQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Entries
  alias PhxLiveStorybook.Rendering.CodeRenderer

  @doc false
  def source_quotes(entries) do
    quotes =
      for %ComponentEntry{module: module} <- Entries.all_leaves(entries) do
        quote do
          @impl PhxLiveStorybook.BackendBehaviour
          def render_source(unquote(module)) do
            unquote(
              try do
                CodeRenderer.render_component_source(module) |> to_raw_html()
              rescue
                _exception ->
                  reraise CompileError,
                          [
                            description: "an error occured while rendering component source",
                            file: module.file_path
                          ],
                          __STACKTRACE__
              end
            )
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
