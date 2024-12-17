defmodule PhoenixStorybook.Story.ComponentDoc do
  @moduledoc false

  use PhoenixStorybook.Web, :component
  import PhoenixStorybook.Components.Icon

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
      class="psb psb-text-base md:psb-text-lg psb-leading-7 psb-text-slate-700 dark:psb-text-slate-300"
    >
      <%= raw(@doc.header) %>
    </div>
    <div :if={@doc && @doc.body && @doc.body != ""}>
      <a
        phx-click={JS.show(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-less")}
        id="read-more"
        class="psb psb-py-2 psb-inline-block psb-text-slate-400 hover:psb-text-indigo-700 dark:hover:psb-text-sky-400 psb-cursor-pointer"
      >
        <.fa_icon
          name="caret-right"
          style={:thin}
          plan={@fa_plan}
          class="psb-relative psb-top-px psb-mr-1"
        /> Read more
      </a>
      <a
        phx-click={JS.hide(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-more")}
        id="read-less"
        class="psb psb-pt-2 psb-pb-4 psb-hidden psb-inline-block psb-text-slate-400 hover:psb-text-indigo-700 dark:hover:psb-text-sky-400 psb-cursor-pointer"
      >
        <.fa_icon name="caret-down" style={:thin} plan={@fa_plan} class="psb-mr-1" /> Read less
      </a>
      <div id="doc-next" class="psb-hidden psb-space-y-4 ">
        <div class="psb psb-doc psb-text-sm md:psb-text-base psb-leading-7 psb-text-slate-700 dark:psb-text-slate-500">
          <%= raw(@doc.body) %>
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
    doc |> String.trim() |> Earmark.as_html() |> elem(1)
  end

  defp read_doc(nil), do: nil
  defp read_doc(doc), do: doc
end
