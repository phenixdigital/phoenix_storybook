defmodule PhoenixStorybook.Story.ComponentDoc do
  @moduledoc false

  use PhoenixStorybook.Web, :component
  import PhoenixStorybook.Components.Icon

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

    assigns =
      if story.storybook_type() == :component and not strip_doc_attributes? do
        assign(assigns, story: story, doc: story.unstripped_doc() |> read_doc())
      else
        assign(assigns, story: story, doc: story.doc() |> read_doc())
      end

    ~H"""
    <div class="psb psb-text-base md:psb-text-lg psb-leading-7 psb-text-slate-700 dark:psb-text-slate-300">
      <%= @doc |> Enum.at(0) |> raw() %>
    </div>
    <% body = Enum.at(@doc, 1) %>
    <div :if={body && body != ""}>
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
          <%= raw(body) %>
        </div>
      </div>
    </div>
    """
  end

  defp read_doc(nil), do: [nil]
  defp read_doc(doc) when is_binary(doc), do: [doc]
  defp read_doc(doc), do: doc
end
