defmodule PhoenixStorybook.Story.Variations do
  @moduledoc false

  use PhoenixStorybook.Web, :component

  import PhoenixStorybook.Components.Icon
  import PhoenixStorybook.NavigationHelpers

  alias Phoenix.HTML.Safe, as: HTMLSafe
  alias PhoenixStorybook.ExtraAssignsHelpers
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.Rendering.{CodeRenderer, ComponentRenderer, RenderingContext}
  alias PhoenixStorybook.Story

  @doc """
  Renders all component's (including live_components) variations: code & preview.

  Depending on story's container option, variation's previews will be rendered:
  - inline by default
  - as an iframe srcdoc for components, when container is iframe
  - as an classic iframe for live_components, when container is iframe
  """

  attr :backend_module, :any
  attr :color_mode, :atom
  attr :color_mode_class, :string
  attr :fa_plan, :atom
  attr :root_path, :string
  attr :socket, :any
  attr :story, Story
  attr :story_path, :string
  attr :theme, :atom
  attr :variation_extra_assigns, :map

  def render_variations(assigns) do
    assigns =
      assign(assigns,
        sandbox_attributes:
          case assigns.story.container() do
            {:div, opts} -> assigns_to_attributes(opts, [:class])
            {:iframe, opts} -> assigns_to_attributes(opts, [:style])
            _ -> []
          end
      )

    ~H"""
    <div class="psb psb:space-y-12 psb:pb-12" id={"story-variations-#{story_id(@story)}"}>
      <%= for variation = %{id: variation_id, description: description} <- @story.variations(),
              extra_attributes = ExtraAssignsHelpers.variation_extra_attributes(variation, assigns),
              rendering_context = RenderingContext.build(assigns.backend_module, assigns.story, variation, extra_attributes) do %>
        <div
          id={anchor_id(variation)}
          class="psb psb-variation-block psb:gap-x-4 psb:grid psb:grid-cols-5"
        >
          <!-- Variation description -->
          <div class="psb psb:group psb:col-span-5 psb:font-medium psb:hover:font-semibold psb:mb-6 psb:border-b psb:border-slate-100 psb:dark:border-slate-600 psb:md:text-lg psb:leading-7 psb:text-slate-700 psb:dark:text-slate-300 psb:flex psb:justify-between">
            <%= link to: "##{anchor_id(variation)}", class: "psb variation-anchor-link" do %>
              <.fa_icon
                style={:light}
                name="link"
                class="psb:hidden! psb:group-hover:inline-block! psb:-ml-8 psb:pr-1 psb:text-slate-400"
                plan={@fa_plan}
              />
              <%= if description do %>
                {description}
              <% else %>
                {variation_id |> to_string() |> String.capitalize() |> String.replace("_", " ")}
              <% end %>
            <% end %>
            <.link
              patch={
                path_to(@socket, @root_path, @story_path, %{
                  tab: :playground,
                  variation_id: variation.id,
                  theme: @theme
                })
              }
              class="psb psb:hidden psb-open-playground-link"
            >
              <span class="psb psb:text-base psb:font-light psb:text-gray-500 psb:dark:text-slate-300 psb:hover:text-indigo-600 psb:dark:hover:text-sky-400 psb:hover:font-medium ">
                Open in playground <.fa_icon style={:regular} name="arrow-right" plan={@fa_plan} />
              </span>
            </.link>
          </div>
          <!-- Variation component preview -->
          <div
            id={"#{anchor_id(variation)}-component"}
            class={[
              "psb psb:border psb:dark:bg-slate-800 psb:border-slate-100 psb:dark:border-slate-600 psb:rounded-md psb:col-span-5 psb:mb-4 psb:lg:mb-0 psb:flex psb:items-center psb:justify-center psb:p-2 psb:bg-white psb:shadow-sm",
              component_layout_class(@story)
            ]}
          >
            <%= case {LayoutView.normalize_story_container(@story.container()), @story.storybook_type()} do %>
              <% {{:iframe, iframe_opts}, :component} -> %>
                <iframe
                  phx-update="ignore"
                  id={iframe_id(@story, variation, @color_mode)}
                  class="psb:w-full psb:border-0"
                  srcdoc={iframe_srcdoc(assigns, rendering_context, iframe_opts)}
                  height="0"
                  onload={iframe_onload_js()}
                  {@sandbox_attributes}
                />
              <% {{:iframe, _iframe_opts}, :live_component} -> %>
                <iframe
                  phx-update="ignore"
                  id={iframe_id(@story, variation, @color_mode)}
                  class="psb:w-full psb:border-0"
                  src={
                    path_to_iframe(@socket, @root_path, @story_path,
                      variation_id: variation.id,
                      theme: @theme,
                      color_mode: @color_mode
                    )
                  }
                  height="0"
                  onload={iframe_onload_js()}
                  {@sandbox_attributes}
                />
              <% {container_with_opts, _component_kind} -> %>
                <div
                  class={[
                    LayoutView.sandbox_class(@socket, container_with_opts, assigns),
                    @color_mode_class
                  ]}
                  {@sandbox_attributes}
                >
                  {ComponentRenderer.render(rendering_context)}
                </div>
            <% end %>
          </div>
          <!-- Variation code -->
          <div
            id={"#{anchor_id(variation)}-code"}
            class={[
              "psb psb:border psb:border-slate-100 psb:dark:border-slate-600 psb:bg-slate-800 psb:rounded-md psb:col-span-5 psb:group psb:relative psb:shadow-sm psb:flex psb:flex-col psb:justify-center",
              code_layout_class(@story)
            ]}
          >
            <div
              phx-click={JS.dispatch("psb:copy-code")}
              class="psb psb:hidden psb:group-hover:block psb:bg-slate-700 psb:text-slate-500 psb:hover:text-slate-100 psb:z-10 psb:absolute psb:top-2 psb:right-2 psb:px-2 psb:py-1 psb:rounded-md psb:cursor-pointer"
            >
              <.fa_icon name="copy" class="psb:text-inherit" plan={@fa_plan} />
            </div>
            {CodeRenderer.render(rendering_context)}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp component_layout_class(story) do
    case story.layout() do
      :one_column -> "psb:lg:mb-4"
      :two_columns -> "psb:lg:col-span-2"
    end
  end

  defp code_layout_class(story) do
    case story.layout() do
      :one_column -> nil
      :two_columns -> "psb:lg:col-span-3"
    end
  end

  defp story_id(story_module) do
    story_module |> Macro.underscore() |> String.replace("/", "_")
  end

  defp anchor_id(%{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end

  defp iframe_id(story, variation, nil) do
    "iframe-#{story_id(story)}-variation-#{variation.id}"
  end

  defp iframe_id(story, variation, color_mode) do
    "iframe-#{story_id(story)}-variation-#{variation.id}-#{color_mode}"
  end

  defp iframe_srcdoc(assigns, rendering_context, iframe_opts) do
    assigns =
      assign(assigns,
        conn: assigns.socket,
        rendering_context: rendering_context,
        iframe_opts: iframe_opts
      )

    ~H"""
    <%= Phoenix.View.render_layout LayoutView, "root_iframe.html", assigns do %>
      <div id="iframe-container" style={@iframe_opts[:style]} class={@color_mode_class}>
        {ComponentRenderer.render(@rendering_context)}
      </div>
    <% end %>
    """
    |> HTMLSafe.to_iodata()
  end

  defp iframe_onload_js do
    """
    javascript:(function(o){
      o.style.height=o.contentWindow.document.body.scrollHeight+'px';
      setTimeout(function() {
        o.style.height=o.contentWindow.document.body.scrollHeight+'px';
      }, 100)
    }(this));
    """
  end
end
