defmodule PhoenixStorybook.Rendering.CodeRenderer do
  @moduledoc """
  Responsible for rendering your components code snippet, for a given
  `PhoenixStorybook.Variation`.

  Uses the `Makeup` libray for syntax highlighting.
  """

  import Phoenix.Component

  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Makeup.Lexers.{ElixirLexer, HEExLexer}
  alias Phoenix.HTML
  alias PhoenixStorybook.Rendering.{RenderingContext, RenderingVariation}
  alias PhoenixStorybook.Stories.Attr
  alias PhoenixStorybook.TemplateHelpers
  alias PhoenixStorybook.ThemeHelpers

  @doc """
  Renders a component code snippet from a `RenderingContext`.
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
              heex =
                component_code_heex(
                  context.story,
                  fun_or_mod,
                  strip_attributes(context, v),
                  v.let,
                  v.slots,
                  context.template
                )

              context.template
              |> TemplateHelpers.set_variation_dom_id(v.dom_id)
              |> TemplateHelpers.replace_template_variation(heex, _indent = true)
            end)

          TemplateHelpers.variation_group_template?(context.template) ->
            heex =
              Enum.map_join(context.variations, "\n", fn v = %RenderingVariation{} ->
                component_code_heex(
                  context.story,
                  fun_or_mod,
                  strip_attributes(context, v),
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

      assigns =
        assign(
          %{__changed__: %{}},
          heex: format_heex(heex, context.options)
        )

      if context.options[:format] == false do
        ~H[<%= @heex %>]
      else
        ~H"""
        <pre class={pre_class()}>
        <%= @heex %>
        </pre>
        """
      end
    end
  end

  @doc """
  Renders source of a component story.
  Returns a rendered HEEx template.
  """
  def render_component_source(story) do
    render_source(story.__component_source__())
  end

  def render_source(source, assigns \\ %{__changed__: %{}})
  def render_source(nil, _assigns), do: nil

  def render_source(source, assigns) do
    assigns = assign(assigns, source: source)

    ~H"""
    <pre class={pre_class()}>
    <%= format_elixir(@source) %>
    </pre>
    """
  end

  defp pre_class do
    """
    lsb highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-border-slate-800 lsb-text-xs md:lsb-text-sm
    lsb-rounded-md lsb-bg-slate-800 lsb-whitespace-pre-wrap lsb-break-normal
    """
  end

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
  defp let_markup(let), do: " :let={#{to_string(let)}}"

  defp attributes_markup(story \\ nil, attributes)

  defp attributes_markup(_story, attributes) when map_size(attributes) == 0, do: ""

  defp attributes_markup(story, attributes) do
    attributes_definitions = if story, do: story.merged_attributes(), else: []
    prefix = if story, do: " ", else: ""

    attributes_markup =
      attributes
      |> Enum.map(fn
        {name, {:eval, val}} ->
          ~s|#{name}={#{val}}|

        {name, val} when is_binary(val) ->
          ~s|#{name}="#{val}"|

        {name, val} ->
          case find_attribute_definitition(attributes_definitions, name) do
            %Attr{type: :global} -> attributes_markup(val)
            %Attr{type: :boolean} when val -> name
            %Attr{type: :boolean} -> nil
            _ -> ~s|#{name}={#{inspect_val(val)}}|
          end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    prefix <> attributes_markup
  end

  defp find_attribute_definitition(attributes_definitions, attr_id) do
    Enum.find(attributes_definitions, fn %Attr{id: id} -> id == attr_id end)
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

  defp format_heex(code, opts) do
    if opts[:format] == false do
      code |> String.trim() |> HTML.raw()
    else
      code
      |> String.trim()
      |> HEExLexer.lex()
      |> HTMLFormatter.format_inner_as_binary([])
      |> HTML.raw()
    end
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

  # If :id is a declared attribute, it is important enough to be shown as component markup,
  # otherwise, we keep it hidden.
  # Theme attributes are also stripped from code when set by the storybook's theme selector.
  defp strip_attributes(
         %RenderingContext{story: story, group_id: group_id, backend_module: backend_module},
         %RenderingVariation{
           id: v_id,
           attributes: attributes
         }
       ) do
    if Enum.any?(story.merged_attributes(), &(&1.id == :id)) do
      Map.put(attributes, :id, TemplateHelpers.unique_variation_id(story, {group_id, v_id}))
    else
      Map.delete(attributes, :id)
    end
    |> then(fn attributes ->
      case ThemeHelpers.theme_strategy(backend_module, :assign) do
        nil -> attributes
        theme_assign -> Map.delete(attributes, theme_assign)
      end
    end)
  end
end
