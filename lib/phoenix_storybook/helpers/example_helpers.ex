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
        # drop doc and extra_sources functions from the source code
        |> Enum.reject(fn
          {:def, _, [{:doc, _, _} | _]} -> true
          {:def, _, [{:extra_sources, _, _} | _]} -> true
          _ -> false
        end)
        # replace `use PhoenixStorybook.Story, :example` with `use Phoenix.LiveView`
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
end
