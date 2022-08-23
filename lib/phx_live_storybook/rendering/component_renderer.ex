defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Story` or `PhxLiveStorybook.StoryGroup`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.{Story, StoryGroup}

  @doc """
  Renders a story or a group of story for a component.
  """
  def render_story(fun_or_mod, story = %Story{}, theme, id) do
    heex =
      component_heex(
        fun_or_mod,
        Map.put(story.attributes, :theme, theme),
        id,
        story.block,
        story.slots
      )

    render_component_heex(fun_or_mod, heex)
  end

  def render_story(fun_or_mod, %StoryGroup{stories: stories}, theme, group_id) do
    heex =
      for story = %Story{id: id} <- stories, into: "" do
        component_heex(
          fun_or_mod,
          Map.put(story.attributes, :theme, theme),
          "#{group_id}-#{id}",
          story.block,
          story.slots
        )
      end

    render_component_heex(fun_or_mod, heex)
  end

  @doc """
  Renders a component.
  """
  def render_component(id, fun_or_mod, assigns, block, slots) do
    heex = component_heex(fun_or_mod, assigns, id, block, slots)
    render_component_heex(fun_or_mod, heex)
  end

  defp component_heex(fun, assigns, id, block, slots) when is_function(fun) do
    """
    <.#{function_name(fun)} #{attributes_markup(assigns, id)}>
      #{block}
      #{slots}
    </.#{function_name(fun)}>
    """
  end

  defp component_heex(module, assigns, id, block, slots) when is_atom(module) do
    """
    <.live_component module={#{inspect(module)}} #{attributes_markup(assigns, id)}>
      #{block}
      #{slots}
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

  defp render_component_heex(fun_or_mod, heex) do
    quoted_code = EEx.compile_string(heex, engine: HTMLEngine)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        aliases: [],
        requires: [Kernel],
        functions: eval_quoted_functions(fun_or_mod)
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp eval_quoted_functions(fun) when is_function(fun) do
    [
      {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]},
      {function_module(fun), [{function_name(fun), 1}]}
    ]
  end

  defp eval_quoted_functions(mod) when is_atom(mod) do
    [
      {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]}
    ]
  end

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
