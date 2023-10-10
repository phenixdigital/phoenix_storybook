defmodule PhoenixStorybook.Search do
  @moduledoc false
  use PhoenixStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.SearchHelpers

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns = %{root_path: _, backend_module: backend_module}, socket) do
    stories = backend_module.leaves()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:show, false)
     |> assign(:all_stories, stories)
     |> assign(:stories, stories)
     |> assign(:fa_plan, backend_module.config(:font_awesome_plan, :free))}
  end

  def handle_event("navigate", %{"path" => path}, socket) do
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("search", %{"search" => %{"input" => ""}}, socket) do
    {:noreply, assign(socket, :stories, socket.assigns.all_stories)}
  end

  def handle_event("search", %{"search" => %{"input" => input}}, socket) do
    stories = SearchHelpers.search_by(input, socket.assigns.all_stories, [:path, :name])
    {:noreply, assign(socket, :stories, stories)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="search-container"
      phx-hook="SearchHook"
      phx-show={show_container()}
      phx-hide={hide_container()}
      class="psb psb-hidden psb-opacity-0 psb-relative psb-z-10 psb-transition-all"
    >
      <div class="psb psb-fixed psb-inset-0 psb-backdrop-blur psb-bg-gray-500 psb-bg-opacity-25">
      </div>

      <div class="psb psb-fixed psb-inset-0 psb-z-10 psb-overflow-y-auto psb-p-4 psb-sm:p-6 psb-md:p-20">
        <div
          id="search-modal"
          phx-show={show_modal()}
          phx-hide={hide_modal()}
          phx-click-away={JS.dispatch("psb:close-search")}
          class="psb psb-opacity-0 psb-scale-90 psb-mx-auto psb-max-w-xl psb-mt-16 psb-transform psb-divide-y psb-divide-gray-100 psb-overflow-hidden psb-rounded-xl psb-bg-white psb-shadow-2xl psb-transition-all"
        >
          <.form
            :let={f}
            for={%{}}
            as={:search}
            phx-debounce={500}
            id="search-form"
            class="psb psb-relative"
          >
            <.fa_icon
              style={:light}
              name="search"
              plan={@fa_plan}
              class="psb-pointer-events-none psb-absolute psb-top-3.5 psb-left-4 psb-h-5 psb-w-5 psb-text-gray-400"
            />
            <%= text_input(f, :input,
              id: "search-input",
              "phx-change": "search",
              "phx-target": @myself,
              placeholder: "Search...",
              autocomplete: "off",
              class:
                "psb psb-h-12 psb-w-full psb-border-0 psb-bg-transparent psb-pl-11 psb-pr-4 psb-text-gray-800 psb-placeholder-gray-400 psb-outline-none focus:psb-ring-0 sm:psb-text-sm"
            ) %>
          </.form>

          <%= if Enum.empty?(@stories) do %>
            <div class="psb psb-text-center psb-text-gray-600 psb-py-4">
              <p>No stories found</p>
            </div>
          <% end %>

          <ul
            id="search-list"
            class="psb psb-max-h-72 psb-scroll-py-2 psb-divide-y psb-divide-gray-200 psb-overflow-y-auto psb-pb-2 psb-text-sm psb-text-gray-800"
          >
            <%= for {story, i} <- Enum.with_index(@stories) do %>
              <li
                id={"story-#{i}"}
                phx-highlight={JS.add_class("psb-bg-slate-50 psb-text-indigo-600")}
                phx-baseline={JS.remove_class("psb-bg-slate-50 psb-text-indigo-600")}
                class="psb psb-flex psb-justify-between psb-group psb-select-none psb-px-4 psb-py-4 psb-space-x-4 psb-cursor-pointer"
                tabindex="-1"
              >
                <.link
                  patch={Path.join(@root_path, story.path)}
                  class="psb psb-font-semibold psb-whitespace-nowrap"
                >
                  <%= story.name %>
                </.link>
                <div class="psb psb-truncate">
                  <%= LayoutView.render_breadcrumb(@socket, story.path, span_class: "psb-text-xs") %>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp show_container(js \\ %JS{}) do
    JS.show(
      js,
      transition: {"psb-ease-out psb-duration-300", "psb-opacity-0", "psb-opacity-100"},
      to: "#search-container"
    )
  end

  defp hide_container(js \\ %JS{}) do
    JS.hide(
      js,
      transition: {"psb-ease-in psb-duration-200", "psb-opacity-100", "psb-opacity-0"},
      to: "#search-container"
    )
  end

  defp show_modal(js \\ %JS{}) do
    JS.transition(
      js,
      {"psb-ease-out psb-duration-300", "psb-opacity-0 psb-scale-90",
       "psb-opacity-100 psb-scale-100"},
      to: "#search-modal"
    )
  end

  defp hide_modal(js \\ %JS{}) do
    JS.transition(
      js,
      {"psb-ease-in psb-duration-200", "psb-opacity-100 psb-scale-100",
       "psb-opacity-0 psb-scale-90"},
      to: "#search-modal"
    )
  end
end
