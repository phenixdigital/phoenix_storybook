defmodule PhxLiveStorybook.Quotes.SourceQuotes do
  @moduledoc false

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
            CodeRenderer.render_component_source(unquote(module))
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
end
