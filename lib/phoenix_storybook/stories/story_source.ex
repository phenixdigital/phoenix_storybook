defmodule PhoenixStorybook.Stories.StorySource do
  @moduledoc false

  require Logger

  # Injecting __component_source__ & __file_path__ functions to the story module.
  # To fetch component source, we need to either call function() or component() on the story
  # module, which are not yet compiled.
  defmacro __before_compile__(env) do
    component_source_path = component_source_path(env)
    story_extra_sources_path = story_extra_sources_path(env)

    quote do
      def __source__ do
        unquote(read_source(env.file))
      end

      def __component_source__ do
        unquote(read_source(component_source_path))
      end

      def __extra_sources__ do
        unquote(
          Macro.escape(
            for {path, full_path} <- story_extra_sources_path, into: %{} do
              {path, read_source(full_path)}
            end
          )
        )
      end

      def __file_path__ do
        unquote(env.file)
      end
    end
  end

  defp component_source_path(env) do
    case component_definition(env) do
      {fun_or_mod, _} -> load_source(fun_or_mod)
      _ -> nil
    end
  rescue
    _ -> component_source_fail(env)
  catch
    _ -> component_source_fail(env)
  end

  defp component_source_fail(env) do
    Logger.warn("cannot load source for component defined in story #{env.file}")
    nil
  end

  defp story_extra_sources_path(env) do
    case extra_sources_definition(env) do
      {source_paths, _} ->
        for path <- source_paths do
          dir = Path.dirname(env.file)
          {path, Path.expand(path, dir)}
        end

      _ ->
        []
    end
  rescue
    _ -> extra_sources_fail(env)
  catch
    _ -> extra_sources_fail(env)
  end

  defp extra_sources_fail(env) do
    Logger.warn("cannot load extra sources for story #{env.file}")
    []
  end

  defp component_definition(env) do
    definitions = Module.definitions_in(env.module)

    cond do
      Enum.member?(definitions, {:function, 0}) ->
        load_definition(env, {:function, 0})

      Enum.member?(definitions, {:component, 0}) ->
        load_definition(env, {:component, 0})

      true ->
        nil
    end
  end

  defp extra_sources_definition(env) do
    definitions = Module.definitions_in(env.module)

    if Enum.member?(definitions, {:extra_sources, 0}) do
      load_definition(env, {:extra_sources, 0})
    else
      nil
    end
  end

  defp load_definition(env, function_and_arity) do
    {:v1, _kind, _meta, ast} = Module.get_definition(env.module, function_and_arity)

    case ast do
      [{_, _, _, ast}] -> Code.eval_quoted(ast, [], env)
      _ -> nil
    end
  end

  defp load_source(nil), do: nil

  defp load_source(function) when is_function(function) do
    module = Function.info(function)[:module]
    load_source(module)
  end

  defp load_source(module) when is_atom(module) do
    module.__info__(:compile)[:source]
  end

  defp read_source(nil), do: nil
  defp read_source(binary) when is_binary(binary), do: File.read!(binary)
  defp read_source(charlist_path), do: charlist_path |> to_string() |> File.read!()
end
