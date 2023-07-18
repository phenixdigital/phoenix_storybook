defmodule PhoenixStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.TagEngine
  alias PhoenixStorybook.Rendering.{RenderingContext, RenderingVariation}
  alias PhoenixStorybook.TemplateHelpers

  @doc """
  Renders a component from a `RenderingContext`.
  Returns a `Phoenix.LiveView.Rendered`.
  """
  def render(context)

  def render(context = %RenderingContext{type: :component, function: function}) do
    render(function, context)
  end

  def render(context = %RenderingContext{type: :live_component, component: component}) do
    render(component, context)
  end

  def render(fun_or_mod, context = %RenderingContext{}) do
    heex =
      cond do
        TemplateHelpers.variation_template?(context.template) ->
          for variation = %RenderingVariation{} <- context.variations, into: "" do
            template_heex(
              fun_or_mod,
              {context.group_id, variation.id},
              context.template,
              variation,
              context.options[:playground_topic]
            )
          end

        TemplateHelpers.variation_group_template?(context.template) ->
          heex =
            for variation = %RenderingVariation{} <- context.variations, into: "" do
              extra_attributes =
                extract_placeholder_attributes(
                  context.template,
                  variation.id,
                  context.options[:playground_topic]
                )

              component_heex(
                fun_or_mod,
                variation.attributes,
                variation.let,
                variation.slots,
                extra_attributes
              )
            end

          context.template
          |> TemplateHelpers.set_variation_dom_id(context.dom_id)
          |> TemplateHelpers.set_js_push_variation_id(context.group_id)
          |> TemplateHelpers.replace_template_variation_group(heex)

        true ->
          context.template
          |> TemplateHelpers.set_variation_dom_id(context.dom_id)
          |> TemplateHelpers.set_js_push_variation_id(context.group_id)
      end

    render_component_heex(fun_or_mod, heex, context.options)
  end

  defp component_heex(fun, assigns, _let, [], extra_attrs) when is_function(fun) do
    """
    <.#{function_name(fun)} #{attributes_markup(assigns)} #{extra_attrs}/>
    """
  end

  defp component_heex(fun, assigns, let, slots, extra_attrs) when is_function(fun) do
    """
    <.#{function_name(fun)} #{let_markup(let)} #{attributes_markup(assigns)} #{extra_attrs}>
      #{slots}
    </.#{function_name(fun)}>
    """
  end

  defp component_heex(module, assigns, _let, [], extra_attrs) when is_atom(module) do
    """
    <.live_component module={#{inspect(module)}} #{attributes_markup(assigns)} #{extra_attrs}/>
    """
  end

  defp component_heex(module, assigns, let, slots, extra_attrs) when is_atom(module) do
    """
    <.live_component module={#{inspect(module)}} #{let_markup(let)} #{attributes_markup(assigns)} #{extra_attrs}>
      #{slots}
    </.live_component>
    """
  end

  defp template_heex(
         fun_or_mod,
         variation_id,
         template,
         %RenderingVariation{dom_id: dom_id, let: let, slots: slots, attributes: attributes},
         playground_topic
       ) do
    extra_attributes = extract_placeholder_attributes(template, variation_id, playground_topic)

    template
    |> TemplateHelpers.set_variation_dom_id(dom_id)
    |> TemplateHelpers.set_js_push_variation_id(variation_id)
    |> TemplateHelpers.replace_template_variation(
      component_heex(fun_or_mod, attributes, let, slots, extra_attributes)
    )
  end

  defp extract_placeholder_attributes(template, _variation_id, _topic = nil) do
    TemplateHelpers.extract_placeholder_attributes(template)
  end

  defp extract_placeholder_attributes(template, variation_id, topic) do
    TemplateHelpers.extract_placeholder_attributes(template, {topic, variation_id})
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: ":let={#{to_string(let)}}"

  defp attributes_markup(attributes) do
    Enum.map_join(attributes, " ", fn
      {name, {:eval, val}} ->
        ~s|#{name}={#{val}}|

      {name, val} when is_binary(val) ->
        ~s|#{name}="#{val}"|

      {name, val} ->
        ~s|#{name}={#{inspect(val, structs: false, limit: :infinity, printable_limit: :infinity)}}|
    end)
  end

  defp render_component_heex(fun_or_mod, heex, opts) do
    quoted_code =
      EEx.compile_string(heex,
        engine: TagEngine,
        caller: __ENV__,
        source: heex,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )

    {evaluated, _, _} =
      Code.eval_quoted_with_env(
        quoted_code,
        [assigns: %{}],
        %Macro.Env{
          requires: [Kernel],
          aliases: eval_quoted_aliases(opts, fun_or_mod),
          functions: eval_quoted_functions(opts, fun_or_mod),
          macros: [{Kernel, Kernel.__info__(:macros)}]
        }
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp eval_quoted_aliases(opts, fun_or_mod) do
    default_aliases = [module(fun_or_mod), Phoenix.LiveView.JS]
    aliases = Keyword.get(opts, :aliases, [])
    eval_quoted_aliases(default_aliases ++ aliases)
  end

  defp eval_quoted_aliases(modules) do
    for mod <- modules, reduce: [] do
      aliases ->
        alias_name = :"Elixir.#{mod |> Module.split() |> Enum.at(-1) |> String.to_atom()}"

        if alias_name == mod do
          aliases
        else
          [{alias_name, mod} | aliases]
        end
    end
  end

  defp eval_quoted_functions(opts, fun) when is_function(fun) do
    [
      {Phoenix.Component, Phoenix.Component.__info__(:functions)},
      {Kernel, Kernel.__info__(:functions)},
      {function_module(fun), [{function_name(fun), 1}]}
    ] ++ extra_imports(opts)
  end

  defp eval_quoted_functions(opts, mod) when is_atom(mod) do
    [
      {Phoenix.Component, Phoenix.Component.__info__(:functions)},
      {Kernel, Kernel.__info__(:functions)}
    ] ++ extra_imports(opts)
  end

  defp extra_imports(opts), do: Keyword.get(opts, :imports, [])

  defp module(fun) when is_function(fun), do: function_module(fun)
  defp module(mod) when is_atom(mod), do: mod

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
