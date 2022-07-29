defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Variation`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.{Variation, VariationGroup}

  @doc """
  Renders a variation of stateless function component, with or without block / slots.
  """
  def render_variation(module, function, variation = %Variation{}, id) do
    heex = component_variation_heex(function, variation, id)
    render_component_heex(module, function, heex)
  end

  def render_variation(module, function, %VariationGroup{variations: variations}, group_id) do
    heex =
      for variation = %Variation{id: id} <- variations, into: "" do
        component_variation_heex(function, variation, "#{group_id}-#{id}")
      end

    render_component_heex(module, function, heex)
  end

  defp component_variation_heex(function, variation = %Variation{}, id) do
    """
    <.#{function_name(function)} #{attributes_markup(variation.attributes, id)}>
      #{variation.block}
      #{variation.slots}
    </.#{function_name(function)}>
    """
  end

  @doc """
  Render a live component, with or without block / slots.
  """
  def render_variation(module, variation = %Variation{}, id) do
    heex = live_component_variation_heex(module, variation, id)
    render_component_heex(module, heex)
  end

  def render_variation(module, %VariationGroup{variations: variations}, group_id) do
    heex =
      for variation = %Variation{id: id} <- variations, into: "" do
        live_component_variation_heex(module, variation, "#{group_id}-#{id}")
      end

    render_component_heex(module, heex)
  end

  defp live_component_variation_heex(module, variation = %Variation{}, id) do
    """
    <.live_component module={#{inspect(module)}} #{attributes_markup(variation.attributes, id)}>
      #{variation.block}
      #{variation.slots}
    </.live_component>
    """
  end

  defp attributes_markup(attributes, id) do
    attributes
    |> Map.put(:id, id)
    |> Enum.map_join(" ", fn
      {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
      {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
    end)
  end

  defp render_component_heex(module, function \\ & &1, heex) do
    quoted_code = EEx.compile_string(heex, engine: HTMLEngine)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        aliases: [],
        requires: [Kernel],
        functions: [
          {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]},
          {module, [{function_name(function), 1}]}
        ]
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp function_name(fun), do: Function.info(fun)[:name]
end
