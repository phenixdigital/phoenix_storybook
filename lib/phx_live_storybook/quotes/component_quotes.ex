defmodule PhxLiveStorybook.Quotes.ComponentQuotes do
  @moduledoc false

  alias Phoenix.HTML.Safe
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  @doc false
  # Precompiling component preview & code snippet for every component / story couple.
  def component_quotes(leave_entries, caller_file) do
    header_quote =
      quote do
        def render_code(module, story_id)
      end

    component_quotes =
      for %ComponentEntry{
            type: type,
            component: component,
            module: module,
            module_name: module_name,
            stories: stories
          } <- leave_entries,
          story <- stories do
        unique_story_id = Macro.underscore("#{module_name}-#{story.id}")

        case type do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_story(unquote(module), unquote(story.id)) do
                unquote(
                  try do
                    ComponentRenderer.render_story(
                      module.function(),
                      story,
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
              def render_story(unquote(module), unquote(story.id)) do
                ComponentRenderer.render_story(
                  unquote(component),
                  unquote(Macro.escape(story)),
                  unquote(unique_story_id)
                )
              end

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
        def render_story(module, story_id) do
          raise "unknown story #{inspect(story_id)} for module #{inspect(module)}"
        end

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
