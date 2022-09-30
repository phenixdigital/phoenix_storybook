defmodule PhxLiveStorybook.Sidebar do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.{FolderEntry, StoryEntry}

  def mount(socket) do
    {:ok, assign(socket, :opened_folders, MapSet.new())}
  end

  def update(assigns = %{current_path: current_path, backend_module: backend_module}, socket) do
    root_path = Path.join("/", live_storybook_path(socket, :root))
    current_path = if current_path, do: Path.join(root_path, current_path), else: root_path
    content_flat_list = backend_module.flat_list()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       root_path: root_path,
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
      class="lsb lsb-text-gray-600 lg:lsb-block lsb-fixed lsb-z-20 lg:lsb-z-auto lsb-w-80 lg:lsb-w-60 lsb-text-base lg:lsb-text-sm lsb-h-screen lsb-flex lsb-flex-col lsb-flex-grow lsb-bg-slate-50 lg:lsb-pt-20 lsb-pb-32 lsb-px-4 lsb-overflow-y-auto"
    >

      <.fa_icon style={:regular} name="xmark" phx-click={JS.dispatch("lsb:close-sidebar")} plan={@fa_plan}
        class="lsb fa-lg lsb-block lg:lsb-hidden lsb-absolute lsb-right-6 lsb-top-6"
      />

      <div class="lsb lsb-bg-white lsb-relative lsb-pointer-events-auto lsb-mb-4">
        <button
          id="search-button"
          phx-click={JS.dispatch("lsb:open-search")}
          class="lsb lsb-hidden lsb-w-full lg:lsb-flex lsb-items-center lsb-text-sm lsb-leading-6 lsb-text-slate-400 lsb-rounded-md lsb-border lsb-border-1 lsb-border-slate-100 hover:lsb-border-slate-200 lsb-py-1.5 lsb-pl-2 lsb-pr-3">

          <.fa_icon style={:light} name="magnifying-glass" plan={@fa_plan}
            class="lsb fa-lg lsb lsb-mr-3 lsb-flex-none lsb-text-slate-400"
          />
          Quick search...
          <span class="lsb lsb-ml-auto lsb-pl-3 lsb-flex-none lsb-text-xs lsb-font-semibold lsb-text-slate-400">⌘K</span>
        </button>
      </div>

      <nav class="lsb lsb-flex-1 xl:lsb-sticky">
        <%= render_stories(assign(assigns, stories: @content_tree, folder_path: @root_path, root: true)) %>
      </nav>

      <div class="lsb lsb-hidden lg:lsb-block lsb-fixed lsb-bottom-3 lsb-left-0 lsb-w-60 lsb-text-md lsb-text-center lsb-text-slate-400 hover:lsb-text-indigo-600 hover:lsb-font-bold">
        <%= link to: "https://github.com/phenixdigital/phx_live_storybook", target: "_blank", class: "lsb" do %>
          <.fa_icon style={:brands} name="github" plan={:pro}/>
          -
          <%= Application.spec(:phx_live_storybook, :vsn) %>
        <% end %>
      </div>
      <.hidden_icons fa_plan={@fa_plan} content_flat_list={@content_flat_list}/>
    </section>
    """
  end

  defp render_stories(assigns) do
    ~H"""
    <ul class="lsb lsb-ml-3 -lsb-mt-1.5 lg:lsb-mt-auto">
      <%= for story <- @stories do %>
        <li class="lsb">
          <%= case story do %>
            <% %FolderEntry{name: name, path: path, entries: entries, icon: folder_icon} -> %>
              <% folder_path = Path.join(@root_path, path) %>
              <% open_folder? = open_folder?(folder_path, assigns) %>
              <div class="lsb lsb-flex lsb-items-center lsb-py-3 lg:lsb-py-1.5 -lsb-ml-2 lsb-group lsb-cursor-pointer lsb-group hover:lsb-text-indigo-600"
                phx-click={click_action(open_folder?)} phx-target={@myself} phx-value-path={folder_path}
              >
                <%= unless @root do %>
                  <%= if open_folder? do %>
                    <.fa_icon name="caret-down" class="lsb lsb-pl-1 lsb-pr-2" plan={@fa_plan}/>
                  <% else %>
                    <.fa_icon name="caret-right" class="lsb lsb-pl-1 lsb-pr-2" plan={@fa_plan}/>
                  <% end %>
                <% end %>

                <%= if folder_icon do %>
                  <.user_icon icon={folder_icon} class="fa-fw lsb-pr-1.5 group-hover:lsb-text-indigo-600" fa_plan={@fa_plan}/>
                <% end %>

                <span class="lsb group-hover:lsb-text-indigo-600">
                  <%= name %>
                </span>
              </div>

              <%= if open_folder? or @root do %>
                <%= render_stories(assign(assigns, stories: entries, folder_path: Path.join(@folder_path, path), root: false)) %>
              <% end %>

            <% %StoryEntry{name: name, path: path, icon: icon} -> %>
              <% story_path = Path.join(@root_path, path) %>
              <div class={story_class(@current_path, story_path)}>
                <%= if icon do %>
                  <.user_icon icon={icon} class="fa-fw -lsb-ml-1 lsb-pr-1.5 group-hover:lsb-text-indigo-600" fa_plan={@fa_plan}/>
                <% end %>
                <%= patch_to(assigns, name, story_path, class: "lsb group-hover:lsb-text-indigo-600") %>
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
      "lsb lsb-flex lsb-items-center -lsb-ml-[12px] lsb-block lsb-border-l lsb-py-2 lg:lsb-py-1 lsb-pl-4 hover:lsb-border-indigo-600 hover:lsb-text-indigo-600 hover:lsb-border-l-1.5 lsb-group"

    if current_path == story_path do
      story_class <> " lsb-font-bold lsb-border-indigo-600 lsb-text-indigo-700 lsb-border-l-1.5"
    else
      story_class <> " lsb-border-slate-200 lsb-text-slate-700"
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
      <%= for %{icon: icon} <- @content_flat_list, !is_nil(icon) do %>
        <.user_icon icon={icon} fa_plan={@fa_plan}/>
      <% end %>
      <%= for icon <- ["caret-down", "caret-right"] do %>
        <.fa_icon name={icon} plan={@fa_plan}/>
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
