defmodule PhxLiveStorybook.Rendering.EntriesRenderer do
  @moduledoc false

  alias PhxLiveStorybook.{ComponentEntry, Entries}
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}
  alias PhxLiveStorybook.{Variation, VariationGroup}

  @doc false
  # Precompiling component preview & code snippet for every component / variation couple.
  def rendering_quote(backend_module, opts) do
    quotes =
      for %ComponentEntry{module: module, module_name: module_name} <-
            component_entries(backend_module, opts[:otp_app]),
          var when is_struct(var, Variation) or is_struct(var, VariationGroup) <-
            module.variations() do
        unique_variation_id = Macro.underscore("#{module_name}-#{var.id}")

        case module.storybook_type() do
          :component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(unquote(module), unquote(var.id)) do
                ComponentRenderer.render_variation(
                  unquote(module).component(),
                  unquote(module).function(),
                  unquote(Macro.escape(var)),
                  unquote(unique_variation_id)
                )
              end

              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(var.id)) do
                CodeRenderer.render_component_code(
                  unquote(module).function(),
                  unquote(Macro.escape(var))
                )
              end
            end

          :live_component ->
            quote do
              @impl PhxLiveStorybook.BackendBehaviour
              def render_variation(unquote(module), unquote(var.id)) do
                ComponentRenderer.render_variation(
                  unquote(module).component(),
                  unquote(Macro.escape(var)),
                  unquote(unique_variation_id)
                )
              end

              @impl PhxLiveStorybook.BackendBehaviour
              def render_code(unquote(module), unquote(var.id)) do
                CodeRenderer.render_live_component_code(
                  unquote(module).component(),
                  unquote(Macro.escape(var))
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

    quotes ++ [default_quote]
  end

  @doc false
  def source_quote(backend_module, opts) do
    quotes =
      for %ComponentEntry{module: module} <- component_entries(backend_module, opts[:otp_app]) do
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

  @doc false
  def component_entries(backend_module, otp_app) do
    content_path =
      otp_app |> Application.get_env(backend_module, []) |> Keyword.get(:content_path)

    folders_config = otp_app |> Application.get_env(backend_module, []) |> Keyword.get(:folders)

    Entries.entries(content_path, folders_config)
    |> Entries.all_leaves()
    |> Enum.filter(fn
      %ComponentEntry{} -> true
      _ -> false
    end)
  end
end
