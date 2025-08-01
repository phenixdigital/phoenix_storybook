defmodule PhoenixStorybook.Rendering.MarkdownRenderer do
  @moduledoc """
  Responsible for rendering Markdown to HTML.

  Supports syntax highlighting for code blocks.
  """

  alias Phoenix.HTML.Safe, as: HTMLSafe
  alias PhoenixStorybook.Rendering.CodeRenderer

  @doc """
  Renders Markdown text as HTML with syntax highlighting for code blocks.
  """
  def markdown_to_html(markdown) do
    markdown |> Earmark.as_html!() |> highlight_code_blocks()
  end

  defp highlight_code_blocks(html) do
    regex = ~r/<pre><code(?:\s+class="(\w*)")?>([^<]*)<\/code><\/pre>/
    Regex.replace(regex, html, &highlight_code_block/3)
  end

  defp highlight_code_block(_full_match, lang, escaped_code) do
    code = escaped_code |> unescape_html() |> IO.iodata_to_binary()

    lang =
      case lang do
        "elixir" -> :elixir
        "heex" -> :heex
        "" -> code |> String.trim_leading() |> guess_lang()
        _ -> :unknown
      end

    CodeRenderer.render_code_block(code, lang, trim: false)
    |> HTMLSafe.to_iodata()
  end

  defp guess_lang("<" <> _), do: :heex
  defp guess_lang(_code), do: :elixir

  entities = [{"&amp;", ?&}, {"&lt;", ?<}, {"&gt;", ?>}, {"&quot;", ?"}, {"&#39;", ?'}]

  for {encoded, decoded} <- entities do
    defp unescape_html(unquote(encoded) <> rest), do: [unquote(decoded) | unescape_html(rest)]
  end

  defp unescape_html(<<c, rest::binary>>), do: [c | unescape_html(rest)]
  defp unescape_html(<<>>), do: []
end
