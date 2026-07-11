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
    <sidebar
      id="psb-sidebar"
      phx-hook="PhoenixStorybook.SidebarHook"
      class="psb psb:text-sidebar-foreground psb:border-r-sidebar-border psb:lg:block psb:fixed psb:z-20 psb:lg:z-auto psb:w-80 psb:lg:w-60 psb:text-base psb:lg:text-sm psb:h-screen psb:flex psb:flex-col psb:flex-grow psb:bg-sidebar psb:p-4 psb:overflow-y-auto"
    >
      <span id="psb-close-sidebar-icon" phx-update="ignore">
        <.fa_icon
          style={:regular}
          name="xmark"
          phx-click={JS.dispatch("psb:close-sidebar")}
          plan={@fa_plan}
          class="fa-lg psb:block! psb:lg:hidden! psb:absolute psb:right-6 psb:top-6 psb:hover:text-sidebar-primary psb:cursor-pointer"
        />
      </span>

      <button
        id="psb-search-button"
        phx-click={JS.dispatch("psb:open-search")}
        class="psb psb:px-3 psb:pb-1.5 psb:pt-2 psb:mb-4 psb:w-full psb:flex psb:items-center psb:gap-1 psb:bg-sidebar-accent psb:text-sidebar-muted-foreground psb:shadow-xs psb:rounded-lg psb:border psb:border-sidebar-border psb:transition-shadow psb:hover:shadow-sm"
      >
        Quick search...
        <div class="psb:ml-auto psb:flex psb:items-center psb:gap-0.25">
          <.kbd text="⌘ K" />
        </div>
      </button>

      <nav class="psb psb:flex-1 psb:xl:sticky">
        {render_entries(assign(assigns, entries: @content_tree, folder_path: @root_path, root: true))}
      </nav>

      <div class="psb psb:hidden psb:lg:block psb:fixed psb:bottom-3 psb:left-0 psb:w-60 psb:text-md psb:text-center psb:text-sidebar-muted-foreground psb:hover:text-sidebar-primary psb:hover:font-bold">
        <.link
          href="https://github.com/phenixdigital/phoenix_storybook"
          target="_blank"
          rel="noreferrer noopener"
          class="psb"
        >
          <.fa_icon style={:brands} name="github" plan={:pro} />
          - {Application.spec(:phoenix_storybook, :vsn)}
        </.link>
      </div>
      <.hidden_icons fa_plan={@fa_plan} content_flat_list={@content_flat_list} />
    </sidebar>
    """
  end

  defp render_entries(assigns) do
    ~H"""
    <ul
      class="psb psb:ml-3 psb:-mt-1.5 psb:lg:mt-auto"
      phx-mounted={unless @root, do: submenu_enter()}
      phx-remove={unless @root, do: submenu_leave()}
    >
      <%= for entry <- sort_entries(@entries) do %>
        <li class="psb">
          <%= case entry do %>
            <% %FolderEntry{name: name, path: path, entries: folder_entries, icon: folder_icon} -> %>
              <% folder_path = Path.join(@root_path, path) %>
              <% open_folder? = open_folder?(folder_path, assigns) %>
              <div
                class="psb psb:flex psb:items-center psb:py-1.5 psb:-ml-2 psb:group psb:cursor-pointer psb:group psb:hover:text-sidebar-primary"
                phx-click={click_action(open_folder?)}
                phx-target={@myself}
                phx-value-path={folder_path}
              >
                <%= unless @root do %>
                  <.scaled_fa_icon
                    name="chevron-right"
                    plan={@fa_plan}
                    class={[
                      "psb:mr-2 psb:size-4 psb:transition-transform psb:origin-center psb:text-sidebar-muted-foreground",
                      open_folder? && "psb:rotate-90"
                    ]}
                  />
                <% end %>

                <%= if folder_icon do %>
                  <.user_icon
                    icon={folder_icon}
                    class="fa-fw psb:-ml-1 psb:mr-1.5 psb:group-hover:text-sidebar-primary"
                    fa_plan={@fa_plan}
                  />
                <% end %>

                <span class="psb psb:group-hover:text-sidebar-primary">
                  {name}
                </span>
              </div>

              <%= if open_folder? or @root do %>
                {render_entries(
                  assign(assigns,
                    entries: folder_entries,
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
                    class="fa-fw psb:-ml-1 psb:mr-1.5 psb:group-hover:text-sidebar-primary"
                    fa_plan={@fa_plan}
                  />
                <% end %>
                <.link
                  patch={if t = assigns[:theme], do: "#{story_path}?theme=#{t}", else: story_path}
                  class="psb psb:block psb:w-full psb:py-2 psb:lg:py-1 psb:group-hover:text-sidebar-primary"
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

  # Renders an `fa_icon` that scales to precisely fill its box, regardless of
  # the glyph's font metrics. The wrapper establishes a CSS container and the
  # icon is sized in container-query units, so the caller only sets the box size
  # (and color, which the glyph inherits via `currentColor`) through `class`.
  attr :name, :string, required: true, doc: "The name of the icon, without the fa- prefix."
  attr :style, :atom, default: :solid, doc: "One of the styles provided by FontAwesome."
  attr :plan, :atom, required: true, doc: "Free plan will make all icons render with solid style."
  attr :class, :any, default: nil, doc: "CSS classes for the wrapper box."
  attr :rest, :global, doc: "Any HTML attribute"

  defp scaled_fa_icon(assigns) do
    ~H"""
    <div
      class={["psb:@container psb:flex psb:items-center psb:justify-center", @class]}
      {@rest}
    >
      <.fa_icon name={@name} style={@style} plan={@plan} class="psb:text-[70cqw]" />
    </div>
    """
  end

  defp sort_entries(entries) do
    if Enum.all?(entries, &is_nil(&1.index)) do
      Enum.sort_by(entries, &{&1.__struct__, &1.name}, fn
        {same, a_name}, {same, b_name} -> a_name <= b_name
        {StoryEntry, _}, {_, _} -> true
        {FolderEntry, _}, {_, _} -> false
      end)
    else
      Enum.sort_by(entries, &{&1.index, &1.name}, fn
        {same, a_name}, {same, b_name} -> a_name <= b_name
        {nil, _}, {_, _} -> false
        {_, _}, {nil, _} -> true
        {a, _}, {b, _} -> a <= b
      end)
    end
  end

  defp story_class(current_path, story_path) do
    story_class =
      "psb psb:flex psb:items-center psb:-ml-[12px] psb:block psb:border-l psb:pl-4 psb:hover:border-sidebar-primary psb:hover:text-sidebar-primary psb:hover:border-l-1.5 psb:group"

    if current_path == story_path do
      story_class <>
        " psb:font-bold psb:border-sidebar-primary psb:text-sidebar-primary psb:border-l-1.5"
    else
      story_class <>
        " psb:border-sidebar-border psb:text-sidebar-foreground"
    end
  end

  defp click_action(_open? = false), do: "open-folder"
  defp click_action(_open? = true), do: "close-folder"

  # Enter/leave animations for a folder's submenu list. The submenu is added and
  # removed from the DOM by the server as folders open and close, so we hook the
  # animation onto `phx-mounted` (open) and `phx-remove` (close). Each applies a
  # `tailwindcss-motion` utility for its duration only — never both at once, so
  # their competing `animation` declarations can't clash. On close LiveView keeps
  # the element around until the leave animation has run.
  defp submenu_enter do
    JS.transition(
      "psb:motion-translate-y-in-[-0.5rem] psb:motion-opacity-in-0 psb:motion-duration-200",
      time: 200
    )
  end

  defp submenu_leave do
    JS.transition(
      "psb:motion-translate-y-out-[-0.5rem] psb:motion-opacity-out-0 psb:motion-duration-150",
      time: 150
    )
  end

  defp open_folder?(path, _assigns = %{opened_folders: opened_folders}) do
    MapSet.member?(opened_folders, path)
  end

  # force caching of all sidebar icons, thus preventing flickering as folders are opened
  defp hidden_icons(assigns) do
    ~H"""
    <div class="psb psb:hidden">
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
