defmodule PhoenixStorybook.Stories.StorySource do
  @moduledoc false

  require Logger

  # Injecting __component_source__ & __file_path__ functions to the story module.
  # To fetch component source, we need to either call function() or component() on the story
  # module, which are not yet compiled.
  defmacro __before_compile__(env) do
    if PhoenixStorybook.enabled?() do
      component_source_path = component_source_path(env)
      story_extra_sources_path = story_extra_sources_path(env)

      quote do
        def __source__ do
          unquote(read_source_file(env.file))
        end

        def __module_source__ do
          unquote(read_source_file(component_source_path))
        end

        def __extra_sources__ do
          unquote(
            Macro.escape(
              for {path, full_path} <- story_extra_sources_path, into: %{} do
                {path, read_source_file(full_path)}
              end
            )
          )
        end

        def __file_path__ do
          unquote(env.file)
        end
      end
    end
  end

  defp component_source_path(env) do
    case component_definition(env) do
      {fun_or_mod, _} -> source_path(fun_or_mod)
      _ -> nil
    end
  rescue
    _e ->
      component_source_fail(env)
  end

  defp component_source_fail(env) do
    Logger.warning("cannot load source for component defined in story #{env.file}")
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
  end

  defp extra_sources_fail(env) do
    Logger.warning("cannot load extra sources for story #{env.file}")
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

  defp source_path(nil), do: nil

  defp source_path(function) when is_function(function) do
    module = Function.info(function)[:module]
    source_path(module)
  end

  defp source_path(module) when is_atom(module) do
    module.__info__(:compile)[:source]
  end

  defp read_source_file(nil), do: nil
  defp read_source_file(binary) when is_binary(binary), do: File.read!(binary)
  defp read_source_file(charlist_path), do: charlist_path |> to_string() |> File.read!()

  ## Extracts a .function declaration from its module.
  ## Preserves the defmodule do ... end
  def strip_function_source(module_source, function) do
    module = Function.info(function)[:module]
    [start, stop] = function_source_location(function, module_source)

    Enum.join(
      [
        "defmodule #{String.replace_leading(to_string(module), "Elixir.", "")} do",
        "",
        "  # stripped ...",
        "",
        module_source
        |> String.split("\n")
        |> Enum.slice(start..stop//1)
        |> Enum.join("\n")
        |> String.trim_trailing(),
        "",
        "  # stripped ...",
        "",
        "end"
      ],
      "\n"
    )
  end

  # Code.fetch_docs/1 does only return the line number for the start of each function.
  # We guess the last line number as being the start of the following function (-1)
  # Returns [start, stop]
  defp function_source_location(function, module_source) do
    Function.info(function)
    [module: module, name: fun_name, arity: arity, env: _, type: _] = Function.info(function)
    {_, _, _, _, _, _, functions} = Code.fetch_docs(module)

    functions
    |> Enum.sort_by(&location/1)
    |> Enum.chunk_every(2, 1)
    |> Enum.map(fn
      [fun1, fun2] -> {header(fun1), location(fun1), location(fun2)}
      [fun] -> {header(fun), location(fun), nil}
    end)
    |> Enum.find(fn {{:function, f, a}, _, _} -> f == fun_name and a == arity end)
    |> then(fn
      {_, start, nil} ->
        [start - 1, find_function_end(module_source, start, -1)]

      {_, start, next_fun_start} ->
        [start - 1, find_function_end(module_source, start, next_fun_start - 1)]
    end)
  end

  defp find_function_end(module_source, start_line, max_line) do
    source_lines = String.split(module_source, "\n")

    max_line..start_line//-1
    |> Enum.find(max_line, fn line ->
      source_lines
      |> Enum.at(line)
      |> String.trim()
      |> Kernel.==("end")
    end)
  end

  defp header({header, _, _, _, _}), do: header
  defp location({_, [generated: _, location: loc], _, _, _}), do: loc
  defp location({_, loc, _, _, _}) when is_integer(loc), do: loc
  defp location(_), do: nil
end
