defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Variation`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.Variation

  @doc """
  Render a stateless function component, with or without block / slots.
  """
  def render_component(module, function, variation = %Variation{}, id) do
    render_component_markup(module, function, """
    <.#{function_name(function)} #{attributes_markup(variation.attributes, id)}>
      #{variation.block}
      #{variation.slots}
    </.#{function_name(function)}>
    """)
  end

  @doc """
  Render a live component, with or without block / slots.
  """
  def render_live_component(module, variation = %Variation{}, id) do
    render_component_markup(module, """
    <.live_component module={#{inspect(module)}} #{attributes_markup(variation.attributes, id)}>
      #{variation.block}
      #{variation.slots}
    </.live_component>
    """)
  end

  defp attributes_markup(attributes, id) do
    attributes
    |> Map.put(:id, id)
    |> Enum.map_join(" ", fn
      {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
      {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
    end)
  end

  defp render_component_markup(module, function \\ & &1, markup) do
    quoted_code = EEx.compile_string(markup, engine: HTMLEngine)

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
