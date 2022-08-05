defmodule PhxLiveStorybook.Rendering.CodeRenderer do
  @moduledoc """
  Responsible for rendering your components code snippet, for a given
  `PhxLiveStorybook.Story`.

  Uses `Makeup` libray for syntax highlighting.
  """

  import Phoenix.LiveView.Helpers

  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Makeup.Lexers.{ElixirLexer, HEExLexer}
  alias Phoenix.HTML
  alias PhxLiveStorybook.{Story, StoryGroup}

  @doc """
  Renders a component code snippet, wrapped in a `<pre>` tag.
  """
  def render_component_code(function_or_module, story_or_group, assigns \\ %{})

  def render_component_code(fun, story = %Story{}, assigns) when is_function(fun) do
    ~H"""
    <pre class={pre_class()}>
    <%= component_code_heex(fun, story) |> format_heex() %>
    </pre>
    """
  end

  def render_component_code(fun, %StoryGroup{stories: stories}, assigns)
      when is_function(fun) do
    heexes = for v <- stories, do: fun |> component_code_heex(v) |> String.replace("\n", "")

    ~H"""
    <pre class={pre_class()}>
    <%= heexes |> Enum.join("\n") |> format_heex() %>
    </pre>
    """
  end

  def render_component_code(mod, story = %Story{}, assigns) when is_atom(mod) do
    ~H"""
    <pre class={pre_class()}>
    <%= live_component_code_heex(mod, story) |> format_heex() %>
    </pre>
    """
  end

  def render_component_code(mod, %StoryGroup{stories: stories}, assigns)
      when is_atom(mod) do
    heexes = for v <- stories, do: mod |> live_component_code_heex(v) |> String.replace("\n", "")

    ~H"""
    <pre class={pre_class()}>
    <%= heexes |> Enum.join("\n") |> format_heex() %>
    </pre>
    """
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

  defp pre_class,
    do:
      "highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-shadow-md lsb-border-slate-800 lsb-rounded-md lsb-bg-slate-800 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal lsb-flex-1"

  defp component_code_heex(function, v = %Story{}) do
    fun = function_name(function)
    self_closed? = is_nil(v.block) and is_nil(v.slots)

    """
    #{"<.#{fun}"}#{for {k, val} <- v.attributes, do: " #{k}=#{format_val(val)}"}#{if self_closed?, do: "/>", else: ">"}
    #{if v.block, do: indent_block(v.block)}#{if v.slots, do: indent_block(v.slots)}
    #{unless self_closed?, do: "<./#{fun}>"}
    """
  end

  defp live_component_code_heex(module, v = %Story{}) do
    mod = module_name(module)
    self_closed? = is_nil(v.block) and is_nil(v.slots)

    """
    #{"<.live_component module={#{mod}}"}#{for {k, val} <- v.attributes, do: " #{k}=#{format_val(val)}"}#{if self_closed?, do: "/>", else: ">"}
    #{if v.block, do: indent_block(v.block)}#{if v.slots, do: indent_block(v.slots)}
    #{unless self_closed?, do: "<./live_component>"}
    """
  end

  defp indent_block(block) do
    block
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join("\n", &"  #{&1}")
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

  defp format_val(val) when is_binary(val), do: inspect(val)
  defp format_val(val), do: "{#{inspect(val)}}"
end
