defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Variation` or `PhxLiveStorybook.VariationGroup`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.TemplateHelpers
  alias PhxLiveStorybook.Stories.{Variation, VariationGroup}

  @doc """
  Renders a specific variation for a given component story.
  Can be a single variation or a variation group.
  Returns a rendered HEEx template.
  """
  def render_variation(story, variation_id, extra_assigns) do
    variation = story.variations() |> Enum.find(&(to_string(&1.id) == to_string(variation_id)))
    template = TemplateHelpers.get_template(story.template(), variation)
    extra_assigns = Map.put(extra_assigns, :id, unique_id(story, variation_id))
    opts = [imports: story.imports(), aliases: story.aliases()]

    case story.storybook_type() do
      :component ->
        render_variation(story.function(), variation, template, extra_assigns, opts)

      :live_component ->
        render_variation(story.component(), variation, template, extra_assigns, opts)
    end
  end

  defp unique_id(story, variation_id) do
    story_module_name = story |> to_string() |> String.split(".") |> Enum.at(-1)
    Macro.underscore("#{story_module_name}-#{variation_id}")
  end

  @doc """
  Renders a variation or a group of variation for a component.
  """
  def render_variation(fun_or_mod, variation = %Variation{}, template, extra_assigns, opts) do
    if TemplateHelpers.variation_group_template?(template) do
      raise "Cannot use <.lsb-variation-group/> placeholder in a variation template."
    end

    heex =
      template_heex(
        template,
        variation.id,
        fun_or_mod,
        Map.merge(variation.attributes, extra_assigns),
        variation.let,
        variation.slots,
        opts[:playground_topic]
      )

    render_component_heex(fun_or_mod, heex, opts)
  end

  def render_variation(
        fun_or_mod,
        %VariationGroup{id: group_id, variations: variations},
        template,
        group_extra_assigns,
        opts
      ) do
    heex =
      cond do
        TemplateHelpers.variation_template?(template) ->
          for variation = %Variation{id: variation_id} <- variations, into: "" do
            extra_assigns = Map.get(group_extra_assigns, variation_id, %{})

            extra_assigns =
              Map.put(extra_assigns, :id, "#{group_extra_assigns.id}-#{variation_id}")

            template_heex(
              template,
              {group_id, variation_id},
              fun_or_mod,
              Map.merge(variation.attributes, extra_assigns),
              variation.let,
              variation.slots,
              opts[:playground_topic]
            )
          end

        TemplateHelpers.variation_group_template?(template) ->
          heex =
            for variation = %Variation{id: variation_id} <- variations, into: "" do
              extra_assigns = %{
                group_extra_assigns
                | id: "#{group_extra_assigns.id}-#{variation_id}"
              }

              extra_attributes =
                extract_placeholder_attributes(
                  template,
                  variation.id,
                  opts[:playground_topic]
                )

              component_heex(
                fun_or_mod,
                Map.merge(variation.attributes, extra_assigns),
                variation.let,
                variation.slots,
                extra_attributes
              )
            end

          template
          |> TemplateHelpers.set_variation_id(group_id)
          |> TemplateHelpers.replace_template_variation_group(heex)

        true ->
          TemplateHelpers.set_variation_id(template, group_id)
      end

    render_component_heex(fun_or_mod, heex, opts)
  end

  @doc false
  def render_multiple_variations(fun_or_mod, variation_or_group, variations, template, opts) do
    heex =
      cond do
        TemplateHelpers.variation_template?(template) ->
          for variation <- variations, into: "" do
            variation_id =
              case variation_or_group do
                %VariationGroup{id: group_id} -> {group_id, variation.id}
                _ -> variation.id
              end

            template_heex(
              template,
              variation_id,
              fun_or_mod,
              variation.attributes,
              variation.let,
              variation.slots,
              opts[:playground_topic]
            )
          end

        TemplateHelpers.variation_group_template?(template) ->
          heex =
            for variation <- variations, into: "" do
              extra_attributes =
                extract_placeholder_attributes(
                  template,
                  variation.id,
                  opts[:playground_topic]
                )

              component_heex(
                fun_or_mod,
                variation.attributes,
                variation.let,
                variation.slots,
                extra_attributes
              )
            end

          template
          |> TemplateHelpers.set_variation_id(variation_or_group.id)
          |> TemplateHelpers.replace_template_variation_group(heex)

        true ->
          TemplateHelpers.set_variation_id(template, variation_or_group.id)
      end

    render_component_heex(fun_or_mod, heex, opts)
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
         template,
         variation_id,
         fun_or_mod,
         assigns,
         let,
         slots,
         playground_topic
       ) do
    extra_attributes = extract_placeholder_attributes(template, variation_id, playground_topic)

    template
    |> TemplateHelpers.set_variation_id(variation_id)
    |> TemplateHelpers.replace_template_variation(
      component_heex(fun_or_mod, assigns, let, slots, extra_attributes)
    )
  end

  defp extract_placeholder_attributes(template, _variation_id, _topic = nil) do
    TemplateHelpers.extract_placeholder_attributes(template)
  end

  defp extract_placeholder_attributes(template, variation_id, topic) do
    TemplateHelpers.extract_placeholder_attributes(template, {topic, variation_id})
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: "let={#{to_string(let)}}"

  defp attributes_markup(attributes) do
    Enum.map_join(attributes, " ", fn
      {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
      {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
    end)
  end

  defp render_component_heex(fun_or_mod, heex, opts) do
    quoted_code = EEx.compile_string(heex, engine: HTMLEngine, caller: __ENV__)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        requires: [Kernel],
        aliases: eval_quoted_aliases(opts, fun_or_mod),
        functions: eval_quoted_functions(opts, fun_or_mod)
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
      {Phoenix.Component, [live_file_input: 2]},
      {function_module(fun), [{function_name(fun), 1}]}
    ] ++ extra_imports(opts)
  end

  defp eval_quoted_functions(opts, mod) when is_atom(mod) do
    [
      {Phoenix.Component, [live_component: 1, live_file_input: 2]}
    ] ++ extra_imports(opts)
  end

  defp extra_imports(opts), do: Keyword.get(opts, :imports, [])

  defp module(fun) when is_function(fun), do: function_module(fun)
  defp module(mod) when is_atom(mod), do: mod

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
