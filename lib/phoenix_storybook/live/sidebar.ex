defmodule PhoenixStorybook.Sidebar do
  @moduledoc false
  use PhoenixStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhoenixStorybook.{FolderEntry, StoryEntry}

  def mount(socket) do
    {:ok, assign(socket, :opened_folders, MapSet.new())}
  end

  def update(
        assigns = %{
          root_path: root_path,
          current_path: current_path,
          backend_module: backend_module
        },
        socket
      ) do
    current_path = if current_path, do: Path.join(root_path, current_path), else: root_path
    content_flat_list = backend_module.flat_list()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       content_tree: backend_module.content_tree(),
       content_flat_list: content_flat_list,
       current_path: current_path
     )
     |> assign_opened_folders(root_path)}
  end

  defp assign_opened_folders(socket = %{assigns: assigns}, root_path) do
    # reading pre-opened folders from index files
    opened_folders =
      if MapSet.size(assigns.opened_folders) == 0 do
        for %FolderEntry{open?: true, path: folder_path} <- socket.assigns.content_flat_list,
            folder_path = folder_path |> to_string() |> String.replace_trailing("/", ""),
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
            |> Path.split()
            |> Enum.reject(&(&1 == ""))
            |> Enum.slice(0..-2//1),
          reduce: {opened_folders, "/"} do
        {opened_folders, path_acc} ->
          path = Path.join(path_acc, path_item)
          {MapSet.put(opened_folders, path), path}
      end

    assign(socket, :opened_folders, opened_folders)
  end

  def render(assigns) do
    ~H"""
    <section
      id="sidebar"
      phx-hook="SidebarHook"
      class="psb psb-text-gray-600 dark:psb-text-slate-400 lg:psb-block psb-fixed psb-z-20 lg:psb-z-auto psb-w-80 lg:psb-w-60 psb-text-base lg:psb-text-sm psb-h-screen psb-flex psb-flex-col psb-flex-grow psb-bg-slate-50 dark:psb-bg-slate-800 lg:psb-pt-20 psb-pb-32 psb-px-4 psb-overflow-y-auto"
    >
      <span id="close-sidebar-icon" phx-update="ignore">
        <.fa_icon
          style={:regular}
          name="xmark"
          phx-click={JS.dispatch("psb:close-sidebar")}
          plan={@fa_plan}
          class="fa-lg psb-block lg:psb-hidden psb-absolute psb-right-6 psb-top-6 hover:psb-text-indigo-600 dark:hover:psb-text-sky-400 psb-cursor-pointer"
        />
      </span>

      <div class="psb psb-bg-white dark:psb-bg-slate-900 psb-relative psb-pointer-events-auto psb-mb-4">
        <button
          id="search-button"
          phx-click={JS.dispatch("psb:open-search")}
          class="psb psb-hidden psb-w-full lg:psb-flex psb-items-center psb-text-sm psb-leading-6 psb-text-slate-400 psb-rounded-md psb-border psb-border-1 psb-border-slate-100 dark:psb-border-slate-600 hover:psb-border-slate-200 psb-py-1.5 psb-pl-2 psb-pr-3"
        >
          <.fa_icon
            style={:light}
            name="magnifying-glass"
            plan={@fa_plan}
            class="fa-lg psb-mr-3 psb-flex-none psb-text-slate-400"
          /> Quick search...
          <span class="psb psb-ml-auto psb-pl-3 psb-flex-none psb-text-xs psb-font-semibold psb-text-slate-400">
            ⌘K
          </span>
        </button>
      </div>

      <nav class="psb psb-flex-1 xl:psb-sticky">
        {render_stories(assign(assigns, stories: @content_tree, folder_path: @root_path, root: true))}
      </nav>

      <div class="psb psb-hidden lg:psb-block psb-fixed psb-bottom-3 psb-left-0 psb-w-60 psb-text-md psb-text-center psb-text-slate-400 hover:psb-text-indigo-600 hover:psb-font-bold">
        <%= link to: "https://github.com/phenixdigital/phoenix_storybook", target: "_blank", class: "psb" do %>
          <.fa_icon style={:brands} name="github" plan={:pro} />
          - {Application.spec(:phoenix_storybook, :vsn)}
        <% end %>
      </div>
      <.hidden_icons fa_plan={@fa_plan} content_flat_list={@content_flat_list} />
    </section>
    """
  end

  defp render_stories(assigns) do
    ~H"""
    <ul class="psb psb-ml-3 -psb-mt-1.5 lg:psb-mt-auto">
      <%= for story <- @stories do %>
        <li class="psb">
          <%= case story do %>
            <% %FolderEntry{name: name, path: path, entries: entries, icon: folder_icon} -> %>
              <% folder_path = Path.join(@root_path, path) %>
              <% open_folder? = open_folder?(folder_path, assigns) %>
              <div
                class="psb psb-flex psb-items-center psb-py-3 lg:psb-py-1.5 -psb-ml-2 psb-group psb-cursor-pointer psb-group hover:psb-text-indigo-600 dark:hover:psb-text-sky-400"
                phx-click={click_action(open_folder?)}
                phx-target={@myself}
                phx-value-path={folder_path}
              >
                <%= unless @root do %>
                  <%= if open_folder? do %>
                    <.fa_icon name="caret-down" class="psb-pl-1 psb-pr-2" plan={@fa_plan} />
                  <% else %>
                    <.fa_icon name="caret-right" class="psb-pl-1 psb-pr-2" plan={@fa_plan} />
                  <% end %>
                <% end %>

                <%= if folder_icon do %>
                  <.user_icon
                    icon={folder_icon}
                    class="fa-fw -psb-ml-1 psb-mr-1.5 group-hover:psb-text-indigo-600 dark:group-hover:psb-text-sky-400"
                    fa_plan={@fa_plan}
                  />
                <% end %>

                <span class="psb group-hover:psb-text-indigo-600 dark:group-hover:psb-text-sky-400">
                  {name}
                </span>
              </div>

              <%= if open_folder? or @root do %>
                {render_stories(
                  assign(assigns,
                    stories: entries,
                    folder_path: Path.join(@folder_path, path),
                    root: false
                  )
                )}
              <% end %>
            <% %StoryEntry{name: name, path: path, icon: icon} -> %>
              <% story_path = Path.join(@root_path, path) %>
              <div class={story_class(@current_path, story_path)}>
                <%= if icon do %>
                  <.user_icon
                    icon={icon}
                    class="fa-fw -psb-ml-1 psb-mr-1.5 group-hover:psb-text-indigo-600 dark:group-hover:psb-text-sky-400"
                    fa_plan={@fa_plan}
                  />
                <% end %>
                <.link
                  patch={if t = assigns[:theme], do: "#{story_path}?theme=#{t}", else: story_path}
                  class="psb group-hover:psb-text-indigo-600 dark:group-hover:psb-text-sky-400"
                >
                  {name}
                </.link>
              </div>
            <% _ -> %>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp story_class(current_path, story_path) do
    story_class =
      "psb psb-flex psb-items-center -psb-ml-[12px] psb-block psb-border-l psb-py-2 lg:psb-py-1 psb-pl-4 hover:psb-border-indigo-600 hover:psb-text-indigo-600 hover:psb-border-l-1.5 psb-group"

    if current_path == story_path do
      story_class <>
        " psb-font-bold psb-border-indigo-600 dark:psb-border-sky-400 psb-text-indigo-700 dark:psb-text-sky-400 psb-border-l-1.5"
    else
      story_class <>
        " psb-border-slate-200 dark:psb-border-slate-500 psb-text-slate-700 dark:psb-text-slate-400"
    end
  end

  defp click_action(_open? = false), do: "open-folder"
  defp click_action(_open? = true), do: "close-folder"

  defp open_folder?(path, _assigns = %{opened_folders: opened_folders}) do
    MapSet.member?(opened_folders, path)
  end

  # force caching of all sidebar icons, thus preventing flickering as folders are opened
  defp hidden_icons(assigns) do
    ~H"""
    <div class="psb psb-hidden">
      <%= for %{icon: icon} <- @content_flat_list, !is_nil(icon) do %>
        <.user_icon icon={icon} fa_plan={@fa_plan} />
      <% end %>
      <%= for icon <- ["caret-down", "caret-right"] do %>
        <.fa_icon name={icon} plan={@fa_plan} />
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
