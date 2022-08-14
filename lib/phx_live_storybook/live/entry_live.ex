defmodule PhxLiveStorybook.EntryLive do
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.{ComponentEntry, PageEntry}
  alias PhxLiveStorybook.Entry.{ComponentEntryLive, PageEntryLive}
  alias PhxLiveStorybook.EntryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"],
       playground_preview_pid: nil,
       playground_error: nil
     )}
  end

  def handle_params(params, _uri, socket) when params == %{} do
    case first_component_entry(socket) do
      nil ->
        {:noreply, socket}

      entry ->
        {:noreply,
         push_patch(socket,
           to:
             live_storybook_path(
               socket,
               :entry,
               String.split(entry.storybook_path, "/", trim: true)
             )
         )}
    end
  end

  def handle_params(params = %{"entry" => entry_path}, _uri, socket) do
    case load_entry(socket, entry_path) do
      nil ->
        raise EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry ->
        {:noreply,
         assign(socket,
           entry: entry,
           entry_path: entry_path,
           page_title: entry.name,
           tab: current_tab(params, entry),
           playground_error: nil
         )
         |> push_event("lsb:close-sidebar", %{"id" => "#sidebar"})}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp current_tab(params, entry) do
    case Map.get(params, "tab") do
      nil ->
        case entry do
          %ComponentEntry{} -> ComponentEntryLive.default_tab()
          %PageEntry{} -> PageEntryLive.default_tab(entry)
        end

      tab ->
        String.to_atom(tab)
    end
  end

  def render(assigns = %{entry: _entry}) do
    ~H"""
    <div class="lsb-space-y-8 lsb-pb-12 lsb-flex lsb-flex-col lsb-h-[calc(100vh_-_7rem)] lg:lsb-h-[calc(100vh_-_4rem)]" id="entry-live" phx-hook="EntryHook">
      <div>
        <div class="lsb-flex lsb-my-6 lsb-items-center">
          <h2 class="lsb-flex-1 lsb-flex-nowrap lsb-whitespace-nowrap lsb-text-xl md:lsb-text-2xl lg:lsb-text-3xl lsb-m-0 lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
            <%= if icon = @entry.icon do %>
              <i class={"#{icon} lsb-pr-2"}></i>
            <% end %>
            <%= @entry.name() %>
          </h2>

          <%=  @entry |> navigation_tabs(assigns) |> render_navigation_tabs(assigns) %>
        </div>
        <div class="lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry.description() %>
        </div>
      </div>

      <%= render_content(@entry, assigns) %>
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp navigation_tabs(%ComponentEntry{}, _assigns) do
    ComponentEntryLive.navigation_tabs()
  end

  defp navigation_tabs(%PageEntry{}, assigns) do
    PageEntryLive.navigation_tabs(assigns)
  end

  defp render_navigation_tabs([], assigns), do: ~H""

  defp render_navigation_tabs(tabs, assigns) do
    ~H"""
    <div class="lsb-flex lsb-flex-items-center">
      <!-- mobile version of navigation tabs -->
      <.form let={f} for={:navigation} id={"#{Macro.underscore(@entry.module)}-navigation-form"} class="entry-nav-form lg:lsb-hidden">
        <%= select f, :tab, navigation_select_options(tabs), "phx-change": "tab-navigation", class: "w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-600 focus:border-indigo-600 sm:text-sm rounded-md", value: @tab %>
      </.form>

      <!-- :lg+ version of navigation tabs -->
      <nav class="entry-tabs lsb-hidden lg:lsb-flex lsb-rounded-lg lsb-border lsb-bg-slate-100 lsb-hover:lsb-bg-slate-200 lsb-h-10 lsb-text-sm lsb-font-medium">
        <%= for {tab, label, icon} <- tabs do %>
          <%= live_patch to: "?tab=#{tab}", class: "lsb-group focus:lsb-outline-none lsb-flex lsb-rounded-md #{active_link(@tab, tab)}" do %>
            <span class={active_span(@tab, tab)}>
              <i class={"#{icon} lg:lsb-mr-2 group-hover:lsb-text-indigo-600"}></i>
              <span class={"group-hover:lsb-text-indigo-600 #{active_text(@tab, tab)}"}>
                <%= label %>
              </span>
            </span>
          <% end %>
        <% end %>
      </nav>
    </div>
    """
  end

  defp navigation_select_options(tabs) do
    for {tab, label, _icon} <- tabs, do: {label, tab}
  end

  defp render_content(%ComponentEntry{}, assigns) do
    ComponentEntryLive.render(assigns)
  end

  defp render_content(%PageEntry{}, assigns) do
    PageEntryLive.render(assigns)
  end

  defp active_link(same, same), do: "lsb-bg-white lsb-opacity-100"

  defp active_link(_tab, _current_tab) do
    "lsb-ml-0.5 lsb-p-1.5 lg:lsb-pl-2.5 lg:lsb-pr-3.5 lsb-items-center lsb-text-slate-600"
  end

  defp active_span(same, same) do
    "lsb-h-full lsb-rounded-md lsb-flex lsb-items-center lsb-bg-white lsb-shadow-sm \
    lsb-ring-opacity-5 lsb-text-indigo-600 lsb-p-1.5 lg:lsb-pl-2.5 lg:lsb-pr-3.5"
  end

  defp active_span(_tab, _current_tab), do: ""

  defp active_text(same, same), do: ""
  defp active_text(_tab, _current_tab), do: "-lsb-ml-0.5"

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp first_component_entry(socket) do
    socket.assigns.backend_module.all_leaves() |> Enum.at(0)
  end

  def handle_event("open-sidebar", _, socket) do
    {:noreply, push_event(socket, "lsb:open-sidebar", %{"id" => "#sidebar"})}
  end

  def handle_event("close-sidebar", _, socket) do
    {:noreply, push_event(socket, "lsb:close-sidebar", %{"id" => "#sidebar"})}
  end

  def handle_event("tab-navigation", %{"navigation" => %{"tab" => tab}}, socket) do
    entry_path =
      live_storybook_path(
        socket,
        :entry,
        String.split(socket.assigns.entry.storybook_path, "/", trim: true)
      )

    {:noreply, push_patch(socket, to: "#{entry_path}?tab=#{tab}")}
  end

  def handle_event("clear-playground-error", _, socket) do
    {:noreply, assign(socket, :playground_error, nil)}
  end

  def handle_info({:playground_preview_pid, pid}, socket) do
    Process.monitor(pid)
    {:noreply, assign(socket, :playground_preview_pid, pid)}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, socket)
      when socket.assigns.playground_preview_pid == pid do
    {:noreply, assign(socket, :playground_error, reason)}
  end
end

defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryTabNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
