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

    test "guesses HEEx for unlabeled tag-like code fences" do
      markdown = """
      ```
      <div>{@label}</div>
      ```
      """

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~r/<pre.*psb highlight.*\/pre>/s
      assert result =~ ~s[<span class="nt">div</span>]
      assert result =~ ~s[&amp;lbrace;@label&amp;rbrace;]
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

    test "preserves inline HTML for compatibility" do
      markdown = ~s[Before <span class="demo">inline</span> after.]

      result = MarkdownRenderer.markdown_to_html(markdown)

      assert result =~ ~s[<span class="demo">inline</span>]
    end
  end
end
