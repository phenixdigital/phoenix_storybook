defmodule PhxLiveStorybook.Components.CodeRenderer do
  import Phoenix.LiveView.Helpers

  alias Makeup.Lexers.HEExLexer
  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Phoenix.HTML
  alias PhxLiveStorybook.Components.Variation

  def render_component_code(function, variation, assigns \\ %{}) do
    ~H"""
    <pre class={pre_class()}>
    <%= component_code_block(function, variation) |> format_code() %>
    </pre>
    """
  end

  def render_live_component_code(module, variation, assigns \\ %{}) do
    ~H"""
    <pre class={pre_class()}>
    <%= live_component_code_block(module, variation) |> format_code() %>
    </pre>
    """
  end

  defp pre_class,
    do:
      "highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-border-slate-800 lsb-rounded-md lsb-bg-slate-800 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal"

  defp component_code_block(function, v = %Variation{}) do
    fun = function_name(function)
    self_closed? = is_nil(v.block) and is_nil(v.slots)

    """
    #{"<.#{fun}"}#{for {k, val} <- v.attributes, do: " #{k}=#{format_val(val)}"}#{if self_closed?, do: "/>", else: ">"}
    #{if v.block, do: v.block}#{if v.slots, do: indent_block(v.slots)}
    #{unless self_closed?, do: "<./#{fun}>"}
    """
  end

  defp live_component_code_block(module, v = %Variation{}) do
    mod = module_name(module)
    self_closed? = is_nil(v.block) and is_nil(v.slots)

    """
    #{"<.live_component module={#{mod}}"}#{for {k, val} <- v.attributes, do: " #{k}=#{format_val(val)}"}#{if self_closed?, do: "/>", else: ">"}
    #{if v.block, do: v.block}#{if v.slots, do: indent_block(v.slots)}
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

  defp format_code(code) do
    code
    |> String.trim()
    |> HEExLexer.lex()
    |> HTMLFormatter.format_inner_as_binary([])
    |> HTML.raw()
  end

  defp function_name(fun), do: Function.info(fun)[:name]
  defp module_name(mod), do: mod |> to_string() |> String.split(".") |> Enum.at(-1)

  defp format_val(val) when is_binary(val), do: inspect(val)
  defp format_val(val), do: "{#{inspect(val)}}"
end
