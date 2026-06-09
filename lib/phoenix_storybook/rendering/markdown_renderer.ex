defmodule PhoenixStorybook.Rendering.MarkdownRenderer do
  @moduledoc """
  Responsible for rendering Markdown to HTML.

  Supports syntax highlighting for code blocks.
  """

  alias Phoenix.HTML.Safe, as: HTMLSafe
  alias PhoenixStorybook.Rendering.CodeRenderer

  @mdex_options [render: [unsafe: true], syntax_highlight: nil]
  @code_block_regex ~r/<pre><code(?:\s+class="([^"]*)")?>([^<]*)<\/code><\/pre>/

  @doc """
  Renders Markdown text as HTML with syntax highlighting for code blocks.
  """
  def markdown_to_html(markdown) do
    markdown |> MDEx.to_html!(@mdex_options) |> highlight_code_blocks()
  end

  defp highlight_code_blocks(html) do
    Regex.replace(@code_block_regex, html, &highlight_code_block/3)
  end

  defp highlight_code_block(_full_match, lang, escaped_code) do
    code = escaped_code |> unescape_html() |> IO.iodata_to_binary()
    lang = lang |> normalize_lang_class()

    lang =
      case lang do
        "elixir" -> :elixir
        "heex" -> :heex
        "" -> code |> String.trim_leading() |> guess_lang()
        _ -> :unknown
      end

    CodeRenderer.render_code_block(code, lang, trim: true)
    |> HTMLSafe.to_iodata()
  end

  defp guess_lang("<" <> _), do: :heex
  defp guess_lang(_code), do: :elixir

  defp normalize_lang_class(lang) when lang in [nil, ""], do: ""
  defp normalize_lang_class("language-" <> lang), do: lang
  defp normalize_lang_class(lang), do: lang

  entities = [
    {"&amp;", ?&},
    {"&lt;", ?<},
    {"&gt;", ?>},
    {"&quot;", ?"},
    {"&#39;", ?'},
    {"&lbrace;", ?{},
    {"&rbrace;", ?}}
  ]

  for {encoded, decoded} <- entities do
    defp unescape_html(unquote(encoded) <> rest), do: [unquote(decoded) | unescape_html(rest)]
  end

  defp unescape_html(<<c, rest::binary>>), do: [c | unescape_html(rest)]
  defp unescape_html(<<>>), do: []
end
