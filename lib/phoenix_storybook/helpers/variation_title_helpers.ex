defmodule PhoenixStorybook.VariationTitleHelpers do
  @moduledoc false

  @doc """
  Returns the title of a variation or variation group: its description, else its humanized id.
  """
  def variation_title(%{description: description}) when is_binary(description), do: description

  def variation_title(%{id: variation_id}),
    do: variation_id |> to_string() |> String.capitalize() |> String.replace("_", " ")
end
