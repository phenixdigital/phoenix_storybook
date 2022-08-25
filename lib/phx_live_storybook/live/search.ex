defmodule PhxLiveStorybook.Search do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias PhxLiveStorybook.LayoutView
  alias Phoenix.LiveView.JS

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns = %{backend_module: backend_module}, socket) do
    root_path = live_storybook_path(socket, :root)
    entries = backend_module.all_leaves()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:root_path, root_path)
     |> assign(:all_entries, List.flatten([entries,entries,entries,entries,entries]))
     |> assign(:entries, List.flatten([entries,entries,entries,entries,entries]))
    }
  end

  def handle_event("navigate", %{"path" => path}, socket) do
   {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("search", %{"search" => %{"input" => input}}, socket) do
    entries = Enum.filter(socket.assigns.all_entries, &String.contains?(String.downcase(&1.name), String.downcase(input)))

   {:noreply, assign(socket, :entries, entries)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="search-container"
      phx-hook="SearchHook"
      phx-show={JS.show(transition: show_transition_classes())}
      phx-hide={JS.hide(transition: hide_transition_classes())}
      class="lsb lsb-hidden lsb-relative lsb-z-10 lsb-duration-300">

      <div class="lsb lsb-fixed lsb-inset-0 lsb-backdrop-blur lsb-bg-gray-500 lsb-bg-opacity-25 lsb-transition-opacity"></div>

      <div class="lsb lsb-fixed lsb-inset-0 lsb-z-10 lsb-overflow-y-auto lsb-p-4 lsb-sm:p-6 lsb-md:p-20">
        <div
          phx-click-away={JS.hide(to: "#search-container", transition: hide_transition_classes())}
          class="lsb lsb-mx-auto lsb-max-w-xl lsb-mt-16 lsb-transform lsb-divide-y lsb-divide-gray-100 lsb-overflow-hidden lsb-rounded-xl lsb-bg-white lsb-shadow-2xl lsb-transition-all">

          <.form let={f} for={:search} phx-debounce={500} id="search-form" class="lsb lsb-relative">
            <i class="fal fa-search lsb lsb-pointer-events-none lsb-absolute lsb-top-3.5 lsb-left-4 lsb-h-5 lsb-w-5 lsb-text-gray-400"></i>
            <%= text_input f, :input, "phx-change": "search", "phx-target": @myself, placeholder: "Search...", autocomplete: "off",  class: "lsb lsb-h-12 lsb-w-full lsb-border-0 lsb-bg-transparent lsb-pl-11 lsb-pr-4 lsb-text-gray-800 lsb-placeholder-gray-400 lsb-outline-none focus:lsb-ring-0 sm:lsb-text-sm"%>
          </.form>

          <%= if Enum.empty?(@entries) do %>
            <div class="lsb lsb-text-center lsb-text-gray-600 lsb-py-4">
              <p>No entries found</p>
            </div>
          <% end %>

          <ul id="search-list" class="lsb lsb-max-h-72 lsb-scroll-py-2 lsb-divide-y lsb-divide-gray-200 lsb-overflow-y-auto lsb-pb-2 lsb-text-sm lsb-text-gray-800">
            <%= for {entry, i} <- Enum.with_index(@entries) do %>
              <% entry_path =  @root_path <> entry.storybook_path %>

              <li id={"entry-#{i}"} class="lsb lsb-flex lsb-justify-between lsb-group lsb-select-none lsb-px-4 lsb-py-4 lsb-cursor-pointer" tabindex="-1">
                <%= live_patch(entry.name, to: entry_path, class: "lsb lsb-font-semibold") %>
                <div>
                  <%= LayoutView.render_breadcrumb(@socket, entry, span_class: "lsb-text-xs") %>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp show_transition_classes do
    {"lsb-ease-out lsb-duration-1000", "lsb-opacity-0 lsb-scale-95", "lsb-opacity-100 lsb-scale-100"}
  end

  defp hide_transition_classes do
    {"lsb-ease-out lsb-duration-200", "lsb-opacity-100 lsb-scale-100", "lsb-opacity-0 lsb-scale-95"}
  end
end
