defmodule PhxLiveStorybook.Rendering.CodeRenderer do
  @moduledoc """
  Responsible for rendering your components code snippet, for a given
  `PhxLiveStorybook.Story`.

  Uses the `Makeup` libray for syntax highlighting.
  """

  import Phoenix.LiveView.Helpers

  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Makeup.Lexers.{ElixirLexer, HEExLexer}
  alias Phoenix.HTML
  alias PhxLiveStorybook.{Story, StoryGroup}

  @doc """
  Renders a `Story` (or `StoryGroup`) code snippet, wrapped in a `<pre>` tag.
  """
  def render_story_code(fun_or_mod, story_or_group, assigns \\ %{})

  def render_story_code(fun_or_mod, s = %Story{}, assigns) do
    ~H"""
    <pre class={pre_class()}>
    <%= component_code_heex(fun_or_mod, s.attributes, s.let, s.block, s.slots) |> format_heex() %>
    </pre>
    """
  end

  def render_story_code(fun_or_mod, %StoryGroup{stories: stories}, assigns) do
    heexes =
      for s <- stories do
        fun_or_mod
        |> component_code_heex(s.attributes, s.let, s.block, s.slots)
        |> String.replace("\n", "")
      end

    ~H"""
    <pre class={pre_class()}>
    <%= heexes |> Enum.join("\n") |> format_heex() %>
    </pre>
    """
  end

  @doc """
  Renders a component code snippet.
  """
  def render_component_code(fun_or_mod, attributes, let, block, slots, assigns \\ %{}) do
    ~H"<%= component_code_heex(fun_or_mod, attributes, let, block, slots) |> format_heex() %>"
  end

  @doc """
  Renders a component's (live or not) source code, wrapped in a `<pre>` tag.
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

  def pre_class,
    do:
      "lsb highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-border-slate-800 lsb-text-xs md:lsb-text-sm lsb-rounded-md lsb-bg-slate-800 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal"

  defp component_code_heex(function, attributes, let, block, slots) when is_function(function) do
    fun = function_name(function)
    self_closed? = is_nil(block) and Enum.empty?(slots)

    trim_empty_lines("""
    #{"<.#{fun}"}#{let_markup(let)}#{attributes_markup(attributes)}#{if self_closed?, do: "/>", else: ">"}
    #{if block, do: indent_slot(block)}
    #{if slots, do: indent_slots(slots)}
    #{unless self_closed?, do: "</.#{fun}>"}
    """)
  end

  defp component_code_heex(module, attributes, let, block, slots) when is_atom(module) do
    mod = module_name(module)
    self_closed? = is_nil(block) and Enum.empty?(slots)

    trim_empty_lines("""
    #{"<.live_component module={#{mod}}"}#{let_markup(let)}#{attributes_markup(attributes)}#{if self_closed?, do: "/>", else: ">"}
    #{if block, do: indent_slot(block)}
    #{if slots, do: indent_slots(slots)}
    #{unless self_closed?, do: "</.live_component>"}
    """)
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: " let={#{to_string(let)}}"

  defp attributes_markup(attributes) when map_size(attributes) == 0, do: ""

  defp attributes_markup(attributes) do
    " " <>
      Enum.map_join(attributes, " ", fn
        {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
        {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
      end)
  end

  defp indent_slots(slots) do
    Enum.map_join(slots, "\n", &indent_slot/1)
  end

  defp indent_slot(slot) do
    slot
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &"  #{&1}")
  end

  defp trim_empty_lines(code) do
    code |> String.split("\n") |> Enum.reject(&(&1 == "")) |> Enum.join("\n")
  end

  defp format_heex(code) do
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
