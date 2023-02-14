defmodule PhoenixStorybook.Stories.Doc do
  @moduledoc """
  Functions to fetch component documentation and render it at HTML.
  """

  require Logger

  @doc """
  Fetch component documentation from component source and format it as HTML.
  - For a live_component, fetches @moduledoc content
  - For a function component, fetches @doc content of the relevant function

  Output HTML is splitted in paragraphs and returned as a list of paragraphs.
  """
  def fetch_doc_as_html(story) do
    case fetch_component_doc(story.storybook_type(), story) do
      :error -> nil
      doc -> doc |> strip_attributes() |> split_paragraphs() |> Enum.map(&format/1)
    end
  end

  defp fetch_component_doc(:component, module) do
    info = Function.info(module.function())
    fetch_function_doc(info[:module], {info[:name], info[:arity]})
  end

  defp fetch_component_doc(:live_component, module) do
    fetch_module_doc(module.component())
  end

  defp fetch_function_doc(module, {fun, arity}) do
    case Code.fetch_docs(module) do
      {_, _, _, _, _, _, function_docs} ->
        case find_function_doc(function_docs, fun, arity) do
          map when is_map(map) -> map |> Map.values() |> Enum.at(0)
          _ -> nil
        end

      _ ->
        Logger.warn("could not fetch function docs from #{inspect(module)}")
        :error
    end
  end

  defp find_function_doc(docs, fun, arity) do
    Enum.find_value(
      docs,
      %{},
      fn
        {{:function, item_fun, item_arity}, _, _, doc, _} ->
          if fun == item_fun && arity == item_arity, do: doc, else: false

        _ ->
          false
      end
    )
  end

  defp fetch_module_doc(module) do
    case Code.fetch_docs(module) do
      {_, _, _, _, module_doc, _, _} ->
        case module_doc do
          map when is_map(map) -> map |> Map.values() |> Enum.at(0)
          _ -> nil
        end

      _ ->
        Logger.warn("could not fetch module doc from #{inspect(module)}")
        :error
    end
  end

  defp strip_attributes(nil), do: nil

  defp strip_attributes(doc) do
    doc |> String.split("## Attributes\n\n") |> hd()
  end

  defp split_paragraphs(nil), do: []

  defp split_paragraphs(doc) do
    doc |> String.split("\n\n") |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp format(doc) do
    doc |> Earmark.as_html!() |> String.trim()
  end
end
