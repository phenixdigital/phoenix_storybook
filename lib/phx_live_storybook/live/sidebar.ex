defmodule PhxLiveStorybook.Sidebar do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  def mount(socket) do
    {:ok, assign(socket, :opened_folders, MapSet.new())}
  end

  def update(assigns = %{current_path: current_path, backend_module: backend_module}, socket) do
    root_path = Path.join("/", live_storybook_path(socket, :root))
    current_path = if current_path, do: Path.join([root_path | current_path]), else: root_path

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       root_path: root_path,
       root_entries: [root_entry(backend_module)],
       entries_flat_list: backend_module.flat_list(),
       current_path: current_path
     )
     |> assign_opened_folders(root_path)}
  end

  defp root_entry(backend_module) do
    %FolderEntry{
      sub_entries: backend_module.entries(),
      storybook_path: "",
      name: "root",
      nice_name: "Storybook",
      icon: "fal fa-book-open"
    }
  end

  defp assign_opened_folders(socket = %{assigns: assigns}, root_path) do
    # reading pre-opened folders from config
    opened_folders =
      if MapSet.size(assigns.opened_folders) == 0 do
        for {folder_path, folder_opts} <- assigns.backend_module.config(:folders, []),
            folder_path = folder_path |> to_string() |> String.replace_trailing("/", ""),
            folder_opts[:open],
            reduce: assigns.opened_folders do
          opened_folders ->
            MapSet.put(opened_folders, Path.join(root_path, folder_path))
        end
      else
        assigns.opened_folders
      end

    # then opening folders based on current request path
    {opened_folders, _} =
      for path_item <-
            assigns.current_path
            |> String.split("/")
            |> Enum.reject(&(&1 == ""))
            |> Enum.slice(0..-2),
          reduce: {opened_folders, "/"} do
        {opened_folders, path_acc} ->
          path = Path.join(path_acc, path_item)
          {MapSet.put(opened_folders, path), path}
      end

    assign(socket, :opened_folders, opened_folders)
  end

  def render(assigns) do
    ~H"""
    <section id="sidebar" phx-hook="SidebarHook"
      class="lsb lsb-text-gray-600 lg:lsb-block lsb-fixed lsb-z-20 lg:lsb-z-auto lsb-w-80 lg:lsb-w-60 lsb-text-base lg:lsb-text-sm lsb-h-screen lsb-flex lsb-flex-col lsb-flex-grow lsb-bg-slate-50 lg:lsb-pt-20 lsb-px-4 lsb-overflow-y-auto"
    >

      <i class="lsb far fa-times fa-lg lsb-block lg:lsb-hidden lsb-absolute lsb-right-6 lsb-top-6" phx-click={JS.dispatch("lsb:close-sidebar")}></i>

      <div class="lsb lsb-bg-white lsb-relative lsb-pointer-events-auto lsb-mb-4">
        <button
          id="search-button"
          phx-click={JS.show(to: "#search-container") |> JS.dispatch("lsb:focus-input", to: "#search-input") |> JS.add_class("lsb-bg-slate-50 lsb-text-indigo-600", to: "#entry-0")}
          class="lsb lsb-hidden lsb-w-full lg:lsb-flex lsb-items-center lsb-text-sm lsb-leading-6 lsb-text-slate-400 lsb-rounded-md lsb-border lsb-border-1 lsb-border-slate-100 hover:lsb-border-slate-200 lsb-py-1.5 lsb-pl-2 lsb-pr-3">

          <i class="lsb fal fa-magnifying-glass fa-lg lsb lsb-mr-3 lsb-flex-none lsb-text-slate-400"></i>
          Quick search...
          <span class="lsb lsb-ml-auto lsb-pl-3 lsb-flex-none lsb-text-xs lsb-font-semibold lsb-text-slate-400">⌘K</span>
        </button>
      </div>

      <nav class="lsb lsb-flex-1 xl:lsb-sticky">
        <%= render_entries(assign(assigns, entries: @root_entries, folder_path: @root_path, root: true)) %>
      </nav>

      <div class="lsb lsb-hidden lg:lsb-block lsb-fixed lsb-bottom-3 lsb-left-0 lsb-w-60 lsb-text-md lsb-text-center lsb-text-slate-400 hover:lsb-text-indigo-600 hover:lsb-font-bold">
        <%= link to: "https://github.com/phenixdigital/phx_live_storybook", target: "_blank", class: "lsb" do %>
          <i class="lsb fa fa-github"></i>
          -
          <%= Application.spec(:phx_live_storybook, :vsn) %>
        <% end %>
      </div>
      <.hidden_icons entries_flat_list={@entries_flat_list}/>
    </section>
    """
  end

  defp render_entries(assigns) do
    ~H"""
    <ul class="lsb lsb-ml-3 -lsb-mt-1.5 lg:lsb-mt-auto">
      <%= for entry <- @entries do %>
        <li class="lsb">
          <%= case entry do %>
            <% %FolderEntry{nice_name: nice_name, storybook_path: storybook_path, sub_entries: sub_entries, icon: folder_icon} -> %>
              <% folder_path = Path.join(@root_path, storybook_path) %>
              <% open_folder? = open_folder?(folder_path, assigns) %>
              <div class="lsb lsb-flex lsb-items-center lsb-py-3 lg:lsb-py-1.5 -lsb-ml-2 lsb-group lsb-cursor-pointer lsb-group hover:lsb-text-indigo-600"
                phx-click={click_action(open_folder?)} phx-target={@myself} phx-value-path={folder_path}
              >
                <%= unless @root do %>
                  <%= if open_folder? do %>
                    <i class="lsb fas fa-caret-down lsb-pl-1 lsb-pr-2"></i>
                  <% else %>
                    <i class="lsb fas fa-caret-right lsb-pl-1 lsb-pr-2"></i>
                  <% end %>
                <% end %>

                <%= if folder_icon do %>
                  <i class={"lsb #{folder_icon} fa-fw lsb-pr-1.5 group-hover:lsb-text-indigo-600"}></i>
                <% end %>

                <span class="lsb group-hover:lsb-text-indigo-600">
                  <%= nice_name %>
                </span>
              </div>

              <%= if open_folder? or @root do %>
                <%= render_entries(assign(assigns, entries: sub_entries, folder_path: Path.join(@folder_path, storybook_path), root: false)) %>
              <% end %>

            <% %ComponentEntry{name: name, storybook_path: storybook_path, icon: icon} -> %>
              <% entry_path = Path.join(@root_path, storybook_path) %>
              <div class={entry_class(@current_path, entry_path)}>
                <%= if icon do %>
                  <i class={"#{icon} fa-fw -lsb-ml-1 lsb-pr-1.5 group-hover:lsb-text-indigo-600"}></i>
                <% end %>
                <%= patch_to(assigns, name, entry_path, class: "lsb group-hover:lsb-text-indigo-600") %>
              </div>

            <% %PageEntry{name: name, storybook_path: storybook_path, icon: icon} -> %>
              <% entry_path = Path.join(@root_path, storybook_path) %>
              <div class={entry_class(@current_path, entry_path)}>
                <%= if icon do %>
                  <i class={"lsb #{icon} fa-fw -lsb-ml-1 lsb-pr-1.5 group-hover:lsb-text-indigo-600"}></i>
                <% end %>
                <%= patch_to(assigns, name, entry_path, class: "lsb group-hover:lsb-text-indigo-600") %>
              </div>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp entry_class(current_path, entry_path) do
    entry_class =
      "lsb -lsb-ml-[12px] lsb-block lsb-border-l lsb-py-2 lg:lsb-py-1 lsb-pl-4 hover:lsb-border-indigo-600 hover:lsb-text-indigo-600 hover:lsb-border-l-1.5 lsb-group"

    if current_path == entry_path do
      entry_class <> " lsb-font-bold lsb-border-indigo-600 lsb-text-indigo-700 lsb-border-l-1.5"
    else
      entry_class <> " lsb-border-slate-200 lsb-text-slate-700"
    end
  end

  defp click_action(_open? = false), do: "open-folder"
  defp click_action(_open? = true), do: "close-folder"

  defp patch_to(assigns, label, path, opts) do
    path =
      case Map.get(assigns, :theme) do
        nil -> path
        theme -> "#{path}?theme=#{theme}"
      end

    live_patch(label, [{:to, path} | opts])
  end

  defp open_folder?(path, _assigns = %{opened_folders: opened_folders}) do
    MapSet.member?(opened_folders, path)
  end

  # force caching of all sidebar icons, thus preventing flickering as folders are opened
  defp hidden_icons(assigns) do
    ~H"""
    <div class="lsb lsb-hidden">
      <%= for %{icon: icon} <- @entries_flat_list do %>
        <i class={icon}></i>
      <% end %>
    </div>
    """
  end

  def handle_event("open-folder", %{"path" => path}, socket) do
    {:noreply, assign(socket, :opened_folders, MapSet.put(socket.assigns.opened_folders, path))}
  end

  def handle_event("close-folder", %{"path" => path}, socket) do
    {:noreply,
     assign(socket, :opened_folders, MapSet.delete(socket.assigns.opened_folders, path))}
  end
end
