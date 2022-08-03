defmodule PhxLiveStorybook.Quotes.ComponentQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Entries
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  @doc false
  # Precompiling component preview & code snippet for every component / variation couple.
  def component_quotes(entries) do
    entries = Entries.all_leaves(entries)

    header_quote =
      quote do
        def render_code(module, variation_id)
      end

    component_quotes =
      for %ComponentEntry{module: module, module_name: module_name} <- entries,
          variation <- module.variations() do
        unique_variation_id = Macro.underscore("#{module_name}-#{variation.id}")

        case module.storybook_type() do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(unquote(module), unquote(variation.id)) do
                unquote(
                  ComponentRenderer.render_variation(
                    module.function(),
                    variation,
                    unique_variation_id
                  )
                  |> to_raw_html()
                )
              end

              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(variation.id)) do
                unquote(
                  CodeRenderer.render_component_code(module.function(), variation)
                  |> to_raw_html()
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(unquote(module), unquote(variation.id)) do
                ComponentRenderer.render_variation(
                  unquote(module).component(),
                  unquote(Macro.escape(variation)),
                  unquote(unique_variation_id)
                )
              end

              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(variation.id)) do
                unquote(
                  CodeRenderer.render_component_code(module.component(), variation)
                  |> to_raw_html()
                )
              end
            end
        end
      end

    default_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def render_variation(module, variation_id) do
          raise "unknown variation #{inspect(variation_id)} for module #{inspect(module)}"
        end

        @impl PhxLiveStorybook.BackendBehaviour
        def render_code(module, variation_id) do
          raise "unknown variation #{inspect(variation_id)} for module #{inspect(module)}"
        end
      end

    [header_quote] ++ component_quotes ++ [default_quote]
  end

  defp to_raw_html(heex) do
    heex
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end
end
