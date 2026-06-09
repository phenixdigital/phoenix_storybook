defmodule PhoenixStorybook.Rendering.MarkdownRendererTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.Rendering.MarkdownRenderer

  describe "markdown_to_html/1" do
    test "renders basic markdown to HTML" do
      markdown = "This is **bold** and *italic* text."
      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ "<strong>bold</strong>"
      assert result =~ "<em>italic</em>"
    end

    test "renders code blocks with syntax highlighting" do
      markdown = """
      Here's some Elixir code:

      ```elixir
      def hello_world do
        "Hello, World!"
      end
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ ~s[<span class="kd">def</span>]
    end

    test "renders explicit heex fences with HEEx highlighting" do
      markdown = """
      ```heex
      <div>{@label}</div>
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s[<span class="nt">div</span>]
      assert result =~ ~s[<span class="na">@label</span>]
    end

    test "guesses Elixir for unlabeled non-tag code fences" do
      markdown = """
      ```
      x = 1 + 1
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ ~s[<span class="n">x</span>]
    end

    test "guesses HEEx for unlabeled tag-like code fences" do
      markdown = """
      ```
      <div>{@label}</div>
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ ~s[<span class="nt">div</span>]
      assert result =~ ~s[<span class="na">@label</span>]
      assert result =~ ">{</span>"
      assert result =~ ">}</span>"
    end

    test "falls back to unknown syntax highlighting for unsupported fenced languages" do
      markdown = """
      ```ruby
      puts "hello"
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ "puts \"hello\""
      refute result =~ ~s[class="lumis"]
    end

    test "supports raw HTML code blocks with non-prefixed classes" do
      markdown = ~s[<pre><code class="elixir">IO.puts(&quot;hello&quot;)</code></pre>]

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ ~s[<span class="nc">IO</span>]
      assert result =~ ~s[<span class="n">puts</span>]
      assert result =~ ~s[&quot;hello&quot;]
    end

    test "supports raw HTML code blocks without a class by guessing the language" do
      markdown = ~s[<pre><code>&lt;div&gt;{@label}&lt;/div&gt;</code></pre>]

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s[<span class="nt">div</span>]
      assert result =~ ~s[<span class="na">@label</span>]
    end

    test "trims fenced code blocks before guessing the language" do
      markdown = """
      ```

          <div>{@label}</div>
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s[<span class="nt">div</span>]
      assert result =~ ~s[<span class="na">@label</span>]
    end

    test "decodes brace entities in unsupported fenced languages before rendering" do
      markdown = """
      ```ruby
      map = %&lbrace;title: "Tom &amp; Jerry"&rbrace;
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s|map = %{title: "Tom &amp; Jerry"}|
      refute result =~ "&lbrace;"
      refute result =~ "&rbrace;"
    end

    test "preserves inline HTML for compatibility" do
      markdown = ~s[Before <span class="demo">inline</span> after.]

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s[<span class="demo">inline</span>]
    end
  end
end
