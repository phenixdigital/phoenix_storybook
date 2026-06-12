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
    {heex, attrs} =
      cond do
        TemplateHelpers.variation_template?(context.template) ->
          context.variations
          |> Enum.with_index()
          |> Enum.map_reduce(%{}, fn {variation = %RenderingVariation{}, index}, attrs ->
            {heex, runtime_attrs} =
              template_heex(
                fun_or_mod,
                {context.group_id, variation.id},
                context.template,
                variation,
                index,
                context.options[:playground_topic]
              )

            {heex, Map.put(attrs, index, runtime_attrs)}
          end)
          |> then(fn {heex, attrs} -> {Enum.join(heex, ""), attrs} end)

        TemplateHelpers.variation_group_template?(context.template) ->
          {components_heex, attrs} =
            context.variations
            |> Enum.with_index()
            |> Enum.map_reduce(%{}, fn {variation = %RenderingVariation{}, index}, attrs ->
              extra_attributes =
                extract_placeholder_attributes(
                  context.template,
                  variation.id,
                  context.options[:playground_topic]
                )

              {heex, runtime_attrs} =
                component_heex(
                  fun_or_mod,
                  variation.attributes,
                  variation.let,
                  variation.slots,
                  index,
                  extra_attributes
                )

              {heex, Map.put(attrs, index, runtime_attrs)}
            end)

          heex =
            context.template
            |> TemplateHelpers.set_variation_dom_id(context.dom_id)
            |> TemplateHelpers.set_js_push_variation_id(context.group_id)
            |> TemplateHelpers.replace_template_variation_group(Enum.join(components_heex, ""))

          {heex, attrs}

        true ->
          {context.template
           |> TemplateHelpers.set_variation_dom_id(context.dom_id)
           |> TemplateHelpers.set_js_push_variation_id(context.group_id), %{}}
      end

    render_component_heex(fun_or_mod, heex, context.options, attrs)
  end

  defp component_heex(fun, assigns, _let, [], index, extra_attrs) when is_function(fun) do
    {attributes_markup, runtime_attrs} = attributes_markup(assigns, index)

    {"""
     <.#{function_name(fun)} #{attributes_markup} #{extra_attrs}/>
     """, runtime_attrs}
  end

  defp component_heex(fun, assigns, let, slots, index, extra_attrs) when is_function(fun) do
    {attributes_markup, runtime_attrs} = attributes_markup(assigns, index)

    {"""
     <.#{function_name(fun)} #{let_markup(let)} #{attributes_markup} #{extra_attrs}>
       #{slots}
     </.#{function_name(fun)}>
     """, runtime_attrs}
  end

  defp component_heex(module, assigns, _let, [], index, extra_attrs) when is_atom(module) do
    {attributes_markup, runtime_attrs} = attributes_markup(assigns, index, [:module])

    {"""
     <.live_component module={#{inspect(module)}} #{attributes_markup} #{extra_attrs}/>
     """, runtime_attrs}
  end

  defp component_heex(module, assigns, let, slots, index, extra_attrs) when is_atom(module) do
    {attributes_markup, runtime_attrs} = attributes_markup(assigns, index, [:module])

    {"""
     <.live_component module={#{inspect(module)}} #{let_markup(let)} #{attributes_markup} #{extra_attrs}>
       #{slots}
     </.live_component>
     """, runtime_attrs}
  end

  defp template_heex(
         fun_or_mod,
         variation_id,
         template,
         %RenderingVariation{dom_id: dom_id, let: let, slots: slots, attributes: attributes},
         index,
         playground_topic
       ) do
    extra_attributes = extract_placeholder_attributes(template, variation_id, playground_topic)

    {component_heex, runtime_attrs} =
      component_heex(fun_or_mod, attributes, let, slots, index, extra_attributes)

    heex =
      template
      |> TemplateHelpers.set_variation_dom_id(dom_id)
      |> TemplateHelpers.set_js_push_variation_id(variation_id)
      |> TemplateHelpers.replace_template_variation(component_heex)

    {heex, runtime_attrs}
  end

  defp extract_placeholder_attributes(template, _variation_id, _topic = nil) do
    TemplateHelpers.extract_placeholder_attributes(template)
  end

  defp extract_placeholder_attributes(template, variation_id, topic) do
    TemplateHelpers.extract_placeholder_attributes(template, {topic, variation_id})
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: ":let={#{to_string(let)}}"

  defp attributes_markup(attributes, index, reserved_attrs \\ []) do
    {eval_attrs, runtime_attrs} =
      attributes
      |> Enum.reject(fn {name, _val} -> name in reserved_attrs end)
      |> Enum.split_with(fn
        {_name, {:eval, _val}} -> true
        _attr -> false
      end)

    eval_attrs_markup =
      Enum.map_join(eval_attrs, " ", fn {name, {:eval, val}} ->
        ~s|#{name}={#{val}}|
      end)

    markup =
      ["{Map.fetch!(@psb_variation_attrs, #{index})}", eval_attrs_markup]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    {markup, Map.new(runtime_attrs)}
  end

  defp render_component_heex(fun_or_mod, heex, opts, attrs) do
    assigns = %{psb_variation_attrs: attrs}

    eval_component_heex(fun_or_mod, heex, opts, assigns)
  end

  defp eval_component_heex(fun_or_mod, heex, opts, assigns) do
    quoted_code =
      TagEngine.compile(heex,
        caller: __ENV__,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )

    env =
      Map.merge(
        __ENV__,
        %{
          requires: [Kernel],
          aliases: eval_quoted_aliases(opts, fun_or_mod),
          functions: eval_quoted_functions(opts, fun_or_mod),
          macros: [{Kernel, Kernel.__info__(:macros)}]
        }
      )

    {evaluated, _, _} =
      Code.eval_quoted_with_env(
        quoted_code,
        [assigns: assigns],
        env
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

  defp extra_imports(opts) do
    for {mod, imports} <- Keyword.get(opts, :imports, []), imp <- imports do
      {mod, [imp]}
    end
  end

  defp module(fun) when is_function(fun), do: function_module(fun)
  defp module(mod) when is_atom(mod), do: mod

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
