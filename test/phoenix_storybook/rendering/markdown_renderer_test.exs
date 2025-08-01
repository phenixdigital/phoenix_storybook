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
  end
end
