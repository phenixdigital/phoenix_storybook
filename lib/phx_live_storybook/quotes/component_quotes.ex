defmodule PhxLiveStorybook.Quotes.ComponentQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}
  alias PhxLiveStorybook.TemplateHelpers

  # Precompiling component preview for every component / variation / theme.
  def render_component_quotes(leave_entries, themes) do
    header_quote =
      quote do
        def render_variation(module, variation_id, extra_assigns \\ %{theme: nil})
      end

    component_quotes =
      for %ComponentEntry{
            type: type,
            component: component,
            function: function,
            module: module,
            module_name: module_name,
            imports: imports,
            aliases: aliases,
            variations: variations,
            template: template
          } <- leave_entries,
          variation <- variations,
          {theme, _label} <- themes do
        template = TemplateHelpers.get_template(template, variation)
        unique_variation_id = Macro.underscore("#{module_name}-#{variation.id}")

        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(
                    unquote(module),
                    unquote(variation.id),
                    extra_assigns = %{theme: unquote(theme)}
                  ) do
                ComponentRenderer.render_variation(
                  unquote(function),
                  unquote(Macro.escape(variation)),
                  unquote(template),
                  Map.put(extra_assigns, :id, unquote(unique_variation_id)),
                  imports: unquote(imports),
                  aliases: unquote(aliases)
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(
                    unquote(module),
                    unquote(variation.id),
                    extra_assigns = %{theme: unquote(theme)}
                  ) do
                ComponentRenderer.render_variation(
                  unquote(component),
                  unquote(Macro.escape(variation)),
                  unquote(template),
                  Map.put(extra_assigns, :id, unquote(unique_variation_id)),
                  imports: unquote(imports),
                  aliases: unquote(aliases)
                )
              end
            end
        end
      end

    component_quotes =
      if Enum.any?(component_quotes) do
        component_quotes
      else
        [
          quote do
            @impl PhxLiveStorybook.BackendBehaviour
            def render_variation(_module, _variation_id, _theme) do
              raise "no variation has been defined yet in this storybook"
            end
          end
        ]
      end

    [header_quote | component_quotes]
  end

  # Precompiling component code snippet for every component / variation.
  def render_code_quotes(leave_entries) do
    header_quote =
      quote do
        def render_code(module, variation_id)
      end

    component_quotes =
      for %ComponentEntry{
            type: type,
            module: module,
            variations: variations,
            template: template
          } <- leave_entries,
          variation <- variations do
        template = TemplateHelpers.get_template(template, variation)

        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(variation.id)) do
                unquote(
                  CodeRenderer.render_variation_code(module.function(), variation, template)
                  |> to_raw_html()
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(variation.id)) do
                unquote(
                  CodeRenderer.render_variation_code(module.component(), variation, template)
                  |> to_raw_html()
                )
              end
            end
        end
      end

    component_quotes =
      if Enum.any?(component_quotes) do
        component_quotes
      else
        [
          quote do
            @impl PhxLiveStorybook.BackendBehaviour
            def render_code(_module, _variation_id) do
              raise "no variation has been defined yet in this storybook"
            end
          end
        ]
      end

    [header_quote | component_quotes]
  end

  defp to_raw_html(heex) do
    heex
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end
end
