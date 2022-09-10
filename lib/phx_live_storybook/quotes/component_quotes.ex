defmodule PhxLiveStorybook.Quotes.ComponentQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  # Precompiling component preview for every component / story / theme.
  # 4 possible cases:
  #   - component / template
  #   - component / no template
  #   - live_component / template
  #   - live_component / no template
  def render_component_quotes(leave_entries, themes, caller_file) do
    header_quote =
      quote do
        def render_story(module, story_id, extra_assigns \\ %{theme: nil})
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
            stories: stories,
            template: template
          } <- leave_entries,
          story <- stories,
          {theme, _label} <- themes do
        template = get_template(template, story)
        unique_story_id = Macro.underscore("#{module_name}-#{story.id}")

        case type do
          :component ->
            if template do
              quote do
                @impl PhxLiveStorybook.BackendBehaviour
                def render_story(
                      unquote(module),
                      unquote(story.id),
                      extra_assigns = %{theme: unquote(theme)}
                    ) do
                  ComponentRenderer.render_story_within_template(
                    unquote(template),
                    unquote(function),
                    unquote(Macro.escape(story)),
                    Map.put(extra_assigns, :id, unquote(unique_story_id)),
                    imports: unquote(imports),
                    aliases: unquote(aliases)
                  )
                end
              end
            else
              quote do
                @impl PhxLiveStorybook.BackendBehaviour
                def render_story(
                      unquote(module),
                      unquote(story.id),
                      %{theme: unquote(theme)}
                    ) do
                  unquote(
                    try do
                      ComponentRenderer.render_story(
                        module.function(),
                        story,
                        %{theme: theme, id: unique_story_id},
                        imports: imports,
                        aliases: aliases
                      )
                      |> to_raw_html()
                    rescue
                      _exception ->
                        reraise CompileError,
                                [
                                  description:
                                    "an error occured while rendering story #{story.id}",
                                  file: caller_file
                                ],
                                __STACKTRACE__
                    end
                  )
                end
              end
            end

          :live_component ->
            if template do
              quote do
                @impl PhxLiveStorybook.BackendBehaviour
                def render_story(
                      unquote(module),
                      unquote(story.id),
                      extra_assigns = %{theme: unquote(theme)}
                    ) do
                  ComponentRenderer.render_story_within_template(
                    unquote(template),
                    unquote(component),
                    unquote(Macro.escape(story)),
                    Map.put(extra_assigns, :id, unquote(unique_story_id)),
                    imports: unquote(imports),
                    aliases: unquote(aliases)
                  )
                end
              end
            else
              quote do
                @impl PhxLiveStorybook.BackendBehaviour
                def render_story(
                      unquote(module),
                      unquote(story.id),
                      extra_assigns = %{theme: unquote(theme)}
                    ) do
                  ComponentRenderer.render_story(
                    unquote(component),
                    unquote(Macro.escape(story)),
                    Map.put(extra_assigns, :id, unquote(unique_story_id)),
                    imports: unquote(imports),
                    aliases: unquote(aliases)
                  )
                end
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
            def render_story(_module, _story_id, _theme) do
              raise "no story has been defined yet in this storybook"
            end
          end
        ]
      end

    [header_quote | component_quotes]
  end

  # Precompiling component code snippet for every component / story.
  def render_code_quotes(leave_entries) do
    header_quote =
      quote do
        def render_code(module, story_id)
      end

    component_quotes =
      for %ComponentEntry{
            type: type,
            module: module,
            stories: stories,
            template: template
          } <- leave_entries,
          story <- stories do
        template = get_template(template, story)

        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(story.id)) do
                unquote(
                  CodeRenderer.render_story_code(module.function(), story, template)
                  |> to_raw_html()
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(story.id)) do
                unquote(
                  CodeRenderer.render_story_code(module.component(), story, template)
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
            def render_code(_module, _story_id) do
              raise "no story has been defined yet in this storybook"
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

  defp get_template(template, _story_or_group = %{template: :unset}), do: template
  defp get_template(_template, _story_or_group = %{template: t}) when t in [nil, false], do: nil
  defp get_template(_template, _story_or_group = %{template: template}), do: template
end
