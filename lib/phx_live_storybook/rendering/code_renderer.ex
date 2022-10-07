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
  alias PhxLiveStorybook.Rendering.{RenderingContext, RenderingVariation}
  alias PhxLiveStorybook.TemplateHelpers
  alias PhxLiveStorybook.Stories.Attr

  def render(context = %RenderingContext{type: :component, function: function}) do
    render(function, context)
  end

  def render(context = %RenderingContext{type: :live_component, component: component}) do
    render(component, context)
  end

  def render(fun_or_mod, context = %RenderingContext{}) do
    if TemplateHelpers.code_hidden?(context.template) do
      render(
        fun_or_mod,
        %RenderingContext{context | template: TemplateHelpers.default_template()}
      )
    else
      heex =
        cond do
          TemplateHelpers.variation_template?(context.template) ->
            Enum.map_join(context.variations, "\n", fn v = %RenderingVariation{} ->
              attributes = maybe_add_id_to_attributes(context.story, v.id, v.attributes)

              heex =
                component_code_heex(
                  context.story,
                  fun_or_mod,
                  attributes,
                  v.let,
                  v.slots,
                  context.template
                )

              context.template
              |> TemplateHelpers.set_variation_dom_id(context.dom_id)
              |> TemplateHelpers.replace_template_variation(heex, _indent = true)
            end)

          TemplateHelpers.variation_group_template?(context.template) ->
            heex =
              Enum.map_join(context.variations, "\n", fn v = %RenderingVariation{} ->
                component_code_heex(
                  context.story,
                  fun_or_mod,
                  v.attributes,
                  v.let,
                  v.slots,
                  context.template
                )
              end)

            TemplateHelpers.replace_template_variation_group(
              context.template,
              heex,
              _indent = true
            )

          true ->
            context.template
        end

      assigns = assign(%{__changed__: %{}}, :heex, heex)

      ~H"""
      <pre class={pre_class()}>
      <%= format_heex(@heex) %>
      </pre>
      """
    end
  end

  @doc """
  Renders source of a component story.
  Returns a rendered HEEx template.
  """
  def render_component_source(story, assigns \\ %{__changed__: %{}}) do
    if source = story.__component_source__() do
      assigns = assign(assigns, source: source)

      ~H"""
      <pre class={pre_class()}>
      <%= format_elixir(@source) %>
      </pre>
      """
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
        {name, {:eval, val}} ->
          ~s|#{name}={#{val}}|

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

  # If :id is a declared attribute, it is important enough to be shown as component markup.
  # Otherwise, we keep it hidden.
  defp maybe_add_id_to_attributes(story, variation_id, attributes) do
    if Enum.any?(story.merged_attributes(), &(&1.id == :id)) do
      Map.put(attributes, :id, TemplateHelpers.unique_variation_id(story, variation_id))
    else
      attributes
    end
  end
end
