defmodule PhxLiveStorybook.Components.CodeRenderer do
  import Phoenix.LiveView.Helpers

  alias Makeup.Lexers.HEExLexer
  alias Makeup.Formatters.HTML.HTMLFormatter
  alias Phoenix.HTML
  alias PhxLiveStorybook.Components.Variation

  def render_component_code(function, variation, assigns \\ %{}) do
    ~H"""
    <pre class="highlight lsb-p-2 md:lsb-p-3 lsb-border lsb-rounded-md">
    <%= code_block(function, variation) |> format_code() %>
    </pre>
    """
  end

  defp code_block(function, v = %Variation{}) do
    fun = function |> function_name() |> to_string()
    self_closed? = is_nil(v.block) and is_nil(v.slots)

    """
    #{"<.#{fun}"}#{for {k, val} <- v.attributes, do: " #{k}=#{format_val(val)}"}#{if self_closed?, do: "/>", else: ">"}
    #{if v.block, do: v.block}#{if v.slots, do: indent_block(v.slots)}
    #{unless self_closed?, do: "<./#{fun}>"}
    """
  end

  defp indent_block(block) do
    block
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&"  #{&1}")
    |> Enum.join("\n")
  end

  defp format_code(code) do
    code
    |> String.trim()
    |> HEExLexer.lex()
    |> HTMLFormatter.format_inner_as_binary([])
    |> HTML.raw()
  end

  defp function_name(fun), do: Function.info(fun)[:name]

  defp format_val(val) when is_binary(val), do: inspect(val)
  defp format_val(val), do: "{#{inspect(val)}}"
end
