defmodule PhoenixStorybook.Helpers.ExampleHelpers do
  @moduledoc false

  def strip_example_source(code) do
    with {:ok, ast, comments} <-
           Code.string_to_quoted_with_comments(code,
             literal_encoder: &{:ok, {:__block__, &2, [&1]}},
             token_metadata: true,
             unescape: false
           ),
         {:defmodule, m1, [aliases, [{{:__block__, m2, [:do]}, {:__block__, m3, block}}]]} <- ast do
      new_block =
        block
        # drop storybook-only functions from the displayed source code
        |> Enum.reject(fn
          {:def, _, [{:doc, _, args} | _]} -> zero_arity?(args)
          {:def, _, [{:container, _, args} | _]} -> zero_arity?(args)
          {:def, _, [{:extra_sources, _, args} | _]} -> zero_arity?(args)
          _ -> false
        end)
        # replace example storybook declarations with plain LiveView source
        |> Enum.map(fn
          {:use, m4, [{:__aliases__, _, [:PhoenixStorybook, :Story]}, _example]} ->
            {:use, m4, [{:__aliases__, [], [:Phoenix, :LiveView]}]}

          other ->
            other
        end)

      new_ast =
        {:defmodule, m1, [aliases, [{{:__block__, m2, [:do]}, {:__block__, m3, new_block}}]]}

      algebra = Code.quoted_to_algebra(new_ast, comments: comments)
      doc = Inspect.Algebra.format(algebra, 98)
      IO.iodata_to_binary(doc)
    else
      _ -> code
    end
  end

  defp zero_arity?(nil), do: true
  defp zero_arity?([]), do: true
  defp zero_arity?(_args), do: false
end
