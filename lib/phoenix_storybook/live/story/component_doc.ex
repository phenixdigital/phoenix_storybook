defmodule PhoenixStorybook.Story.ComponentDoc do
  @moduledoc false

  use PhoenixStorybook.Web, :component
  import PhoenixStorybook.Components.Icon

  alias PhoenixStorybook.Rendering.MarkdownRenderer
  alias PhoenixStorybook.Stories.Doc

  @doc """
  Renders story documentation.

  `story.doc()` may return:
  - `nil`
  - a string, when `doc/0` has been implemented in the story
  - a `[header]` array, when a single line of doc has been fetched from component `@doc`
  - a `[header, body]` array, when `@doc` contains more than a single line of documentation
  """

  attr :story, PhoenixStorybook.Story
  attr :fa_plan, :atom
  attr :backend_module, :any

  def render_documentation(assigns = %{story: story}) do
    strip_doc_attributes? = assigns.backend_module.config(:strip_doc_attributes, true)

    doc =
      cond do
        story.storybook_type() in [:page, :example] ->
          story.doc() |> render_page_doc() |> read_doc()

        story.storybook_type() == :component and not strip_doc_attributes? ->
          story.unstripped_doc() |> read_doc()

        true ->
          story.doc() |> read_doc()
      end

    assigns = assign(assigns, :doc, doc)

    ~H"""
    <div
      :if={@doc}
      class="psb psb:text-base psb:md:text-lg psb:leading-7 psb:text-foreground"
    >
      {raw(@doc.header)}
    </div>
    <div :if={@doc && @doc.body && @doc.body != ""}>
      <a
        phx-click={
          JS.toggle_class("psb:grid-rows-[1fr]", to: "#psb-doc-next")
          |> JS.toggle(to: "#psb-read-more")
          |> JS.toggle(to: "#psb-read-less")
          |> JS.toggle_class("psb:rotate-90", to: "#psb-doc-caret")
        }
        class="psb psb:flex psb:items-center psb:gap-1 psb:py-2 psb:text-muted-foreground psb:hover:text-primary psb:cursor-pointer"
      >
        <.scaled_fa_icon
          id="psb-doc-caret"
          name="chevron-right"
          style={:thin}
          plan={@fa_plan}
          class="psb:size-3 psb:transition-transform psb:origin-center"
        />
        <span id="psb-read-more" class="psb">Read more</span>
        <span id="psb-read-less" class="psb psb:hidden">Read less</span>
      </a>
      <div
        id="psb-doc-next"
        class="psb psb:grid psb:grid-rows-[0fr] psb:transition-[grid-template-rows] psb:duration-300 psb:ease-out"
      >
        <div class="psb psb:overflow-hidden">
          <div class="psb psb-doc psb:pt-2 psb:text-sm psb:md:text-base psb:leading-7 psb:text-muted-foreground">
            {raw(@doc.body)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_page_doc(nil), do: nil

  defp render_page_doc(doc) do
    case String.split(doc, "\n\n", parts: 2) do
      [header] -> %Doc{header: format(header)}
      [header, body] -> %Doc{header: format(header), body: format(body)}
    end
  end

  defp format(doc) do
    doc |> String.trim() |> MarkdownRenderer.markdown_to_html()
  end

  defp read_doc(nil), do: nil
  defp read_doc(doc), do: doc
end
