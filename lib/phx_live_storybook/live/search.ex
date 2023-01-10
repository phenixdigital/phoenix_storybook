defmodule PhxLiveStorybook.Search do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.SearchHelpers

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
      class="lsb lsb-hidden lsb-opacity-0 lsb-relative lsb-z-10 lsb-transition-all">

      <div class="lsb lsb-fixed lsb-inset-0 lsb-backdrop-blur lsb-bg-gray-500 lsb-bg-opacity-25"></div>

      <div class="lsb lsb-fixed lsb-inset-0 lsb-z-10 lsb-overflow-y-auto lsb-p-4 lsb-sm:p-6 lsb-md:p-20">
        <div
          id="search-modal"
          phx-show={show_modal()}
          phx-hide={hide_modal()}
          phx-click-away={JS.dispatch("lsb:close-search")}
          class="lsb lsb-opacity-0 lsb-scale-90 lsb-mx-auto lsb-max-w-xl lsb-mt-16 lsb-transform lsb-divide-y lsb-divide-gray-100 lsb-overflow-hidden lsb-rounded-xl lsb-bg-white lsb-shadow-2xl lsb-transition-all">

          <.form :let={f} for={:search} phx-debounce={500} id="search-form" class="lsb lsb-relative">
            <.fa_icon style={:light} name="search" plan={@fa_plan}
              class="lsb-pointer-events-none lsb-absolute lsb-top-3.5 lsb-left-4 lsb-h-5 lsb-w-5 lsb-text-gray-400"
            />
            <%= text_input f, :input, id: "search-input", "phx-change": "search", "phx-target": @myself, placeholder: "Search...", autocomplete: "off",  class: "lsb lsb-h-12 lsb-w-full lsb-border-0 lsb-bg-transparent lsb-pl-11 lsb-pr-4 lsb-text-gray-800 lsb-placeholder-gray-400 lsb-outline-none focus:lsb-ring-0 sm:lsb-text-sm"%>
          </.form>

          <%= if Enum.empty?(@stories) do %>
            <div class="lsb lsb-text-center lsb-text-gray-600 lsb-py-4">
              <p>No stories found</p>
            </div>
          <% end %>

          <ul id="search-list" class="lsb lsb-max-h-72 lsb-scroll-py-2 lsb-divide-y lsb-divide-gray-200 lsb-overflow-y-auto lsb-pb-2 lsb-text-sm lsb-text-gray-800">
            <%= for {story, i} <- Enum.with_index(@stories) do %>
              <li
                id={"story-#{i}"}
                phx-highlight={JS.add_class("lsb-bg-slate-50 lsb-text-indigo-600")}
                phx-baseline={JS.remove_class("lsb-bg-slate-50 lsb-text-indigo-600")}
                class="lsb lsb-flex lsb-justify-between lsb-group lsb-select-none lsb-px-4 lsb-py-4 lsb-space-x-4 lsb-cursor-pointer"
                tabindex="-1">
                <.link patch={Path.join(@root_path, story.path)} class="lsb lsb-font-semibold lsb-whitespace-nowrap">
                  <%= story.name %>
                </.link>
                <div class="lsb lsb-truncate">
                  <%= LayoutView.render_breadcrumb(@socket, story.path, span_class: "lsb-text-xs") %>
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
      transition: {"lsb-ease-out lsb-duration-300", "lsb-opacity-0", "lsb-opacity-100"},
      to: "#search-container"
    )
  end

  defp hide_container(js \\ %JS{}) do
    JS.hide(
      js,
      transition: {"lsb-ease-in lsb-duration-200", "lsb-opacity-100", "lsb-opacity-0"},
      to: "#search-container"
    )
  end

  defp show_modal(js \\ %JS{}) do
    JS.transition(
      js,
      {"lsb-ease-out lsb-duration-300", "lsb-opacity-0 lsb-scale-90",
       "lsb-opacity-100 lsb-scale-100"},
      to: "#search-modal"
    )
  end

  defp hide_modal(js \\ %JS{}) do
    JS.transition(
      js,
      {"lsb-ease-in lsb-duration-200", "lsb-opacity-100 lsb-scale-100",
       "lsb-opacity-0 lsb-scale-90"},
      to: "#search-modal"
    )
  end
end
