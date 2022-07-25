defmodule PhxLiveStorybook.Rendering.EntriesRenderer do
  @moduledoc false

  alias PhxLiveStorybook.{ComponentEntry, Entries, FolderEntry, Variation}
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}

  @doc false
  # Precompiling component preview & code snippet for every component / variation couple.
  def rendering_quote(backend_module, opts) do
    for %ComponentEntry{module: module} <- component_entries(backend_module, opts[:otp_app]),
        variation = %Variation{id: variation_id} <- module.variations() do
      case module.storybook_type() do
        :component ->
          quote do
            def render_component(unquote(module), unquote(variation_id)) do
              ComponentRenderer.render_component(
                unquote(module).component(),
                unquote(module).function(),
                unquote(Macro.escape(variation))
              )
            end

            def render_code(unquote(module), unquote(variation_id)) do
              CodeRenderer.render_component_code(
                unquote(module).function(),
                unquote(Macro.escape(variation))
              )
            end
          end

        :live_component ->
          quote do
            def render_component(unquote(module), unquote(variation_id)) do
              ComponentRenderer.render_live_component(
                unquote(module).component(),
                unquote(Macro.escape(variation))
              )
            end

            def render_code(unquote(module), unquote(variation_id)) do
              CodeRenderer.render_live_component_code(
                unquote(module).component(),
                unquote(Macro.escape(variation))
              )
            end
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
    for entry <- entries, reduce: acc do
      acc ->
        case entry do
          %ComponentEntry{} -> [entry | acc]
          %FolderEntry{sub_entries: entries} -> collect_components(entries, acc)
        end
    end
  end
end
