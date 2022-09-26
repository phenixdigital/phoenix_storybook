defmodule PhxLiveStorybook.Stories.StoryComponentSource do
  @moduledoc false

  # Injecting __component_source__ & __file_path__ functions to the story module.
  # To fetch component source, we need to either call function() or component() on the story
  # module, which are not yet compiled.
  defmacro __before_compile__(env) do
    component_source_path =
      case component_definition(env) do
        {fun_or_mod, _} -> load_source(fun_or_mod)
        _ -> nil
      end

    quote do
      def __component_source__ do
        unquote(read_source(component_source_path))
      end

      def __file_path__ do
        unquote(env.file)
      end
    end
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
  defp read_source(charlist_path), do: charlist_path |> to_string() |> File.read!()
end
