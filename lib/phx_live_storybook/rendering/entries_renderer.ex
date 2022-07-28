defmodule PhxLiveStorybook.Rendering.EntriesRenderer do
  @moduledoc false

  alias PhxLiveStorybook.{ComponentEntry, Entries, FolderEntry, Variation}
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  @doc false
  # Precompiling component preview & code snippet for every component / variation couple.
  def rendering_quote(backend_module, opts) do
    for %ComponentEntry{module: module, module_name: module_name} <-
          component_entries(backend_module, opts[:otp_app]),
        variation = %Variation{id: variation_id} <- module.variations() do
      unique_variation_id = Macro.underscore("#{module_name}-#{variation.id}")

      case module.storybook_type() do
        :component ->
          quote do
            @impl PhxLiveStorybook.BackendBehaviour
            def render_component(unquote(module), unquote(variation_id)) do
              ComponentRenderer.render_component(
                unquote(module).component(),
                unquote(module).function(),
                unquote(Macro.escape(variation)),
                unquote(unique_variation_id)
              )
            end

            @impl PhxLiveStorybook.BackendBehaviour
            def render_code(unquote(module), unquote(variation_id)) do
              CodeRenderer.render_component_code(
                unquote(module).function(),
                unquote(Macro.escape(variation))
              )
            end
          end

        :live_component ->
          quote do
            @impl PhxLiveStorybook.BackendBehaviour
            def render_component(unquote(module), unquote(variation_id)) do
              ComponentRenderer.render_live_component(
                unquote(module).component(),
                unquote(Macro.escape(variation)),
                unquote(unique_variation_id)
              )
            end

            @impl PhxLiveStorybook.BackendBehaviour
            def render_code(unquote(module), unquote(variation_id)) do
              CodeRenderer.render_live_component_code(
                unquote(module).component(),
                unquote(Macro.escape(variation))
              )
            end
          end

        _ ->
          []
      end
    end
  end

  @doc false
  def source_quote(backend_module, opts) do
    for %ComponentEntry{module: module} <- component_entries(backend_module, opts[:otp_app]) do
      quote do
        @impl PhxLiveStorybook.BackendBehaviour
        def render_source(unquote(module)) do
          CodeRenderer.render_component_source(unquote(module))
        end
      end
    end
  end

  @doc false
  def component_entries(backend_module, otp_app) do
    otp_app
    |> Application.get_env(backend_module, [])
    |> Keyword.get(:content_path)
    |> Entries.entries()
    |> collect_components()
  end

  # Recursive traversal of the entry tree to build a flattened list of components
  defp collect_components(entries, acc \\ []) do
    for entry <- Enum.reverse(entries), reduce: acc do
      acc ->
        case entry do
          %ComponentEntry{} -> [entry | acc]
          %FolderEntry{sub_entries: entries} -> collect_components(Enum.reverse(entries), acc)
          _ -> acc
        end
    end
  end
end
