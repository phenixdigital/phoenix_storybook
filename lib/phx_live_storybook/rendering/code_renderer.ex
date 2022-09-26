defmodule PhxLiveStorybook.Rendering.CodeRenderer do
  @moduledoc """
  Responsible for rendering your components code snippet, for a given
  `PhxLiveStorybook.Variation`.

  Uses the `Makeup` libray for syntax highlighting.
  """

  import Phoenix.Component

  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Makeup.Lexers.{ElixirLexer, HEExLexer}
  alias Phoenix.HTML
  alias PhxLiveStorybook.TemplateHelpers
  alias PhxLiveStorybook.Stories.{Attr, Variation, VariationGroup}

  @doc """
  Renders code snippet of a specific variation for a given component story.
  Returns a rendered HEEx template.
  """
  def render_variation_code(story, variation_id, opts \\ []) do
    variation = story.variations() |> Enum.find(&(to_string(&1.id) == to_string(variation_id)))
    template = TemplateHelpers.get_template(story.template(), variation)

    case story.storybook_type() do
      :component ->
        render_variation_code(story, story.function(), variation, template, opts)

      :live_component ->
        render_variation_code(story, story.component(), variation, template, opts)
    end
  end

  defp render_variation_code(
         story,
         fun_or_mod,
         variation_or_group,
         template,
         opts,
         assigns \\ %{}
       )

  defp render_variation_code(story, fun_or_mod, v = %Variation{}, template, opts, assigns) do
    if TemplateHelpers.code_hidden?(template) do
      render_variation_code(
        story,
        fun_or_mod,
        v,
        TemplateHelpers.default_template(),
        opts,
        assigns
      )
    else
      heex = component_code_heex(story, fun_or_mod, v.attributes, v.let, v.slots, template)
      heex = TemplateHelpers.replace_template_variation(template, heex, _indent = true)

      ~H"""
      <pre class={pre_class()}>
      <%= format_heex(heex, opts) %>
      </pre>
      """
    end
  end

  defp render_variation_code(
         story,
         fun_or_mod,
         group = %VariationGroup{variations: variations},
         template,
         opts,
         assigns
       ) do
    if TemplateHelpers.code_hidden?(template) do
      render_variation_code(
        story,
        fun_or_mod,
        group,
        TemplateHelpers.default_template(),
        opts,
        assigns
      )
    else
      heex =
        cond do
          TemplateHelpers.variation_template?(template) ->
            Enum.map_join(variations, "\n", fn v ->
              heex =
                component_code_heex(story, fun_or_mod, v.attributes, v.let, v.slots, template)

              TemplateHelpers.replace_template_variation(template, heex, _indent = true)
            end)

          TemplateHelpers.variation_group_template?(template) ->
            heex =
              Enum.map_join(variations, "\n", fn v ->
                component_code_heex(story, fun_or_mod, v.attributes, v.let, v.slots, template)
              end)

            TemplateHelpers.replace_template_variation_group(template, heex, _indent = true)

          true ->
            template
        end

      ~H"""
      <pre class={pre_class()}>
      <%= format_heex(heex, opts) %>
      </pre>
      """
    end
  end

  @doc """
  Renders code snippet for a set of variations.
  """
  def render_multiple_variations_code(story, fun_or_mod, variations, template, assigns \\ %{}) do
    if TemplateHelpers.code_hidden?(template) do
      render_multiple_variations_code(
        fun_or_mod,
        variations,
        TemplateHelpers.default_template(),
        assigns
      )
    else
      heex =
        cond do
          TemplateHelpers.variation_template?(template) ->
            Enum.map_join(variations, "\n", fn v ->
              heex =
                component_code_heex(story, fun_or_mod, v.attributes, v.let, v.slots, template)

              TemplateHelpers.replace_template_variation(template, heex, _indent = true)
            end)

          TemplateHelpers.variation_group_template?(template) ->
            heex =
              Enum.map_join(variations, "\n", fn v ->
                component_code_heex(story, fun_or_mod, v.attributes, v.let, v.slots, template)
              end)

            TemplateHelpers.replace_template_variation_group(template, heex, _indent = true)

          true ->
            template
        end

      ~H"<%= format_heex(heex) %>"
    end
  end

  @doc """
  Renders source of a component story.
  Returns a rendered HEEx template.
  """
  def render_component_source(module, assigns \\ %{}) do
    if source = component_source(module, module.storybook_type()) do
      ~H"""
      <pre class={pre_class()}>
      <%= source |> File.read!() |> format_elixir() %>
      </pre>
      """
    end
  end

  defp component_source(module, :component) do
    if module.function() do
      component = Function.info(module.function())[:module]
      component.__info__(:compile)[:source]
    end
  end

  defp component_source(module, :live_component) do
    if module.component() do
      module.component().__info__(:compile)[:source]
    end
  end

  @doc false
  def pre_class,
    do:
      "lsb highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-border-slate-800 lsb-text-xs md:lsb-text-sm lsb-rounded-md lsb-bg-slate-800 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal"

  defp component_code_heex(story, function, attributes, let, slots, template)
       when is_function(function) do
    fun = function_name(function)
    self_closed? = Enum.empty?(slots)

    trim_empty_lines("""
    #{"<.#{fun}"}#{let_markup(let)}#{template_attributes_markup(template)}#{attributes_markup(story, attributes)}#{if self_closed?, do: "/>", else: ">"}
    #{if slots, do: indent_slots(slots)}
    #{unless self_closed?, do: "</.#{fun}>"}
    """)
  end

  defp component_code_heex(story, module, attributes, let, slots, template)
       when is_atom(module) do
    mod = module_name(module)
    self_closed? = Enum.empty?(slots)

    trim_empty_lines("""
    #{"<.live_component module={#{mod}}"}#{let_markup(let)}#{template_attributes_markup(template)}#{attributes_markup(story, attributes)}#{if self_closed?, do: "/>", else: ">"}
    #{if slots, do: indent_slots(slots)}
    #{unless self_closed?, do: "</.live_component>"}
    """)
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: " let={#{to_string(let)}}"

  defp attributes_markup(story \\ nil, attributes)

  defp attributes_markup(_story, attributes) when map_size(attributes) == 0, do: ""

  defp attributes_markup(story, attributes) do
    attributes_definition = if story, do: story.merged_attributes(), else: []
    prefix = if story, do: " ", else: ""

    prefix <>
      Enum.map_join(attributes, " ", fn
        {name, val} when is_binary(val) ->
          ~s|#{name}="#{val}"|

        {name, val} ->
          if global_attribute?(attributes_definition, name) do
            attributes_markup(val)
          else
            ~s|#{name}={#{inspect_val(val)}}|
          end
      end)
  end

  defp global_attribute?(attributes_definition, attr_id) do
    case Enum.find(attributes_definition, fn %Attr{id: id} -> id == attr_id end) do
      nil -> false
      %Attr{type: :global} -> true
      %Attr{type: _} -> false
    end
  end

  defp template_attributes_markup(template) do
    case TemplateHelpers.extract_placeholder_attributes(template) do
      "" -> ""
      attributes -> " " <> attributes
    end
  end

  defp inspect_val(struct = %{__struct__: struct_name}) when is_struct(struct) do
    full_name = struct_name |> to_string() |> String.replace_leading("Elixir.", "")
    aliased_name = full_name |> String.split(".") |> Enum.at(-1)
    struct |> inspect() |> String.replace(full_name, aliased_name)
  end

  defp inspect_val(val), do: inspect(val, structs: false)

  defp indent_slots(slots) do
    Enum.map_join(slots, "\n", &indent_slot/1)
  end

  defp indent_slot(slot, indent_size \\ 2) do
    indent = Enum.map_join(1..indent_size, fn _ -> " " end)

    slot
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &(indent <> &1))
  end

  defp trim_empty_lines(code) do
    code |> String.split("\n") |> Enum.reject(&(&1 == "")) |> Enum.join("\n")
  end

  defp format_heex(code, opts \\ [])

  defp format_heex(code, format: false) do
    code |> String.trim() |> HTML.raw()
  end

  defp format_heex(code, _opts) do
    code
    |> String.trim()
    |> HEExLexer.lex()
    |> HTMLFormatter.format_inner_as_binary([])
    |> HTML.raw()
  end

  defp format_elixir(code) do
    code
    |> String.trim()
    |> ElixirLexer.lex()
    |> HTMLFormatter.format_inner_as_binary([])
    |> HTML.raw()
  end

  defp function_name(fun), do: Function.info(fun)[:name]
  defp module_name(mod), do: mod |> to_string() |> String.split(".") |> Enum.at(-1)
end
