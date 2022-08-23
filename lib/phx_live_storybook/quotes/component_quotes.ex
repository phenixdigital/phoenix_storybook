defmodule PhxLiveStorybook.Quotes.ComponentQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  # Precompiling component preview for every component / story / theme.
  def render_component_quotes(leave_entries, themes, caller_file) do
    header_quote =
      quote do
        def render_story(module, story_id, theme)
      end

    component_quotes =
      for %ComponentEntry{
            type: type,
            component: component,
            module: module,
            module_name: module_name,
            stories: stories
          } <- leave_entries,
          story <- stories,
          {theme, _label} <- themes do
        unique_story_id = Macro.underscore("#{module_name}-#{story.id}")

        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_story(unquote(module), unquote(story.id), unquote(theme)) do
                unquote(
                  try do
                    ComponentRenderer.render_story(
                      module.function(),
                      story,
                      theme,
                      unique_story_id
                    )
                    |> to_raw_html()
                  rescue
                    _exception ->
                      reraise CompileError,
                              [
                                description: "an error occured while rendering story #{story.id}",
                                file: caller_file
                              ],
                              __STACKTRACE__
                  end
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_story(unquote(module), unquote(story.id), unquote(theme)) do
                ComponentRenderer.render_story(
                  unquote(component),
                  unquote(Macro.escape(story)),
                  unquote(theme),
                  unquote(unique_story_id)
                )
              end
            end
        end
      end

    default_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def render_story(module, story_id, theme) do
          raise "unknown story #{inspect(story_id)} for module #{inspect(module)}"
        end
      end

    [header_quote] ++ component_quotes ++ [default_quote]
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
            stories: stories
          } <- leave_entries,
          story <- stories do
        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(story.id)) do
                unquote(
                  CodeRenderer.render_story_code(module.function(), story)
                  |> to_raw_html()
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(story.id)) do
                unquote(
                  CodeRenderer.render_story_code(module.component(), story)
                  |> to_raw_html()
                )
              end
            end
        end
      end

    default_quote =
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def render_code(module, story_id) do
          raise "unknown story #{inspect(story_id)} for module #{inspect(module)}"
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
