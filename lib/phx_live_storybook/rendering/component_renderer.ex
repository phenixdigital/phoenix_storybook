defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Variation` or `PhxLiveStorybook.VariationGroup`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.{Variation, VariationGroup}

  @doc """
  Renders a variation or a group of variation for a component.
  """
  def render_variation(fun, variation = %Variation{}, id) when is_function(fun) do
    heex = component_variation_heex(fun, variation, id)
    render_component_heex(fun, heex)
  end

  def render_variation(fun, %VariationGroup{variations: variations}, group_id)
      when is_function(fun) do
    heex =
      for variation = %Variation{id: id} <- variations, into: "" do
        component_variation_heex(fun, variation, "#{group_id}-#{id}")
      end

    render_component_heex(fun, heex)
  end

  def render_variation(module, variation = %Variation{}, id) when is_atom(module) do
    heex = component_variation_heex(module, variation, id)
    render_component_heex(heex)
  end

  def render_variation(module, %VariationGroup{variations: variations}, group_id)
      when is_atom(module) do
    heex =
      for variation = %Variation{id: id} <- variations, into: "" do
        component_variation_heex(module, variation, "#{group_id}-#{id}")
      end

    render_component_heex(heex)
  end

  defp component_variation_heex(fun, variation = %Variation{}, id) when is_function(fun) do
    """
    <.#{function_name(fun)} #{attributes_markup(variation.attributes, id)}>
      #{variation.block}
      #{variation.slots}
    </.#{function_name(fun)}>
    """
  end

  defp component_variation_heex(module, variation = %Variation{}, id) when is_atom(module) do
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

  defp render_component_heex(fun \\ & &1, heex) do
    quoted_code = EEx.compile_string(heex, engine: HTMLEngine)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        aliases: [],
        requires: [Kernel],
        functions: [
          {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]},
          {function_module(fun), [{function_name(fun), 1}]}
        ]
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
