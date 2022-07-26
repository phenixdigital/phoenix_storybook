defmodule PhxLiveStorybook.Sidebar do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  def mount(socket) do
    {:ok, assign(socket, :opened_folders, MapSet.new())}
  end

  def update(assigns = %{current_path: current_path, backend_module: backend_module}, socket) do
    root_path = live_storybook_path(socket, :home)
    current_path = if current_path, do: [root_path | current_path], else: [root_path]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       root_path: root_path,
       root_entries: backend_module.storybook_entries(),
       current_path: current_path
     )
     |> assign_opened_folders(root_path)
     |> assign_folder_icons(root_path)}
  end

  defp assign_opened_folders(socket = %{assigns: assigns}, root_path) do
    # reading pre-opened folders from config
    opened_folders =
      for {folder_path, folder_opts} <- assigns.backend_module.config(:folders, []),
          folder_opts[:open],
          reduce: assigns.opened_folders do
        opened_folders ->
          MapSet.put(opened_folders, "#{root_path}/#{folder_path}")
      end

    # then opening folders based on current request path
    {opened_folders, _} =
      for path_item <- Enum.slice(assigns.current_path, 0..2),
          reduce: {opened_folders, nil} do
        {opened_folders, path_acc} ->
          path = if path_acc, do: "#{path_acc}/#{path_item}", else: path_item
          {MapSet.put(opened_folders, path), path}
      end

    assign(socket, :opened_folders, opened_folders)
  end

  defp assign_folder_icons(socket = %{assigns: assigns}, root_path) do
    folder_icons =
      for {folder_path, folder_opts} <- assigns.backend_module.config(:folders, []),
          folder_opts[:icon],
          into: %{},
          do: {"#{root_path}/#{folder_path}", folder_opts[:icon]}

    assign(socket, :folder_icons, folder_icons)
  end

  def render(assigns) do
    ~H"""
    <section
      class="lsb-fixed lsb-text-sm lsb-w-60 lsb-h-screen lsb-flex lsb-flex-col lsb-flex-grow lsb-bg-slate-50 lsb-pt-4 lsb-px-4 lsb-overflow-y-auto"
    >
      <nav class="lsb-flex-1 xl:lsb-sticky">
        <%= render_entries(assign(assigns, entries: @root_entries, folder_path: [@root_path])) %>
      </nav>

        <div class="lsb-fixed lsb-bottom-3 lsb-left-0 lsb-w-60 lsb-text-md lsb-text-center lsb-text-slate-400 hover:lsb-text-indigo-600">
          <%= link to: "https://github.com/phenixdigital/phx_live_storybook", target: "_blank" do %>
            <i class="fa fa-github lsb-pr-1"></i>
            <%= Application.spec(:phx_live_storybook, :vsn) %>
          <% end %>
        </div>
    </section>
    """
  end

  defp render_entries(assigns = %{folder_icons: folder_icons}) do
    ~H"""
    <ul class="lsb-ml-3">
      <%= for entry <- @entries do %>
        <li>
          <%= case entry do %>
            <% %FolderEntry{name: folder_name, sub_entries: sub_entries} -> %>
              <% current_path = Enum.join(@folder_path ++ [folder_name], "/") %>
              <% open_folder? = open_folder?(current_path, assigns) %>
              <div class="lsb-flex lsb-items-center lsb-py-1.5 lsb-group lsb-cursor-pointer hover:lsb-text-indigo-600"
                phx-click={click_action(open_folder?)} phx-target={@myself} phx-value-path={current_path}
              >
                <%= if open_folder? do %>
                  <i class="fas fa-caret-down lsb-pl-1 lsb-pr-2"></i>
                <% else %>
                  <i class="fas fa-caret-right lsb-pl-1 lsb-pr-2"></i>
                <% end %>

                <%= if icon = Map.get(folder_icons, current_path) do %>
                  <i class={"#{icon} lsb-pr-1.5"}></i>
                <% end %>

                <%= String.capitalize(folder_name) %>
              </div>
              <%= if open_folder? do %>
                <%= render_entries(assign(assigns, entries: sub_entries, folder_path: @folder_path ++ [folder_name])) %>
              <% end %>

            <% %ComponentEntry{name: name, module: module, module_name: module_name} -> %>
              <div class={entry_class(@current_path, @folder_path, module_name)}>
                <%= if icon = module.icon() do %>
                  <i class={"#{icon} -lsb-ml-1 lsb-pr-1.5"}></i>
                <% end %>
                <%= live_patch name, to: entry_path(@folder_path, module_name) %>
              </div>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp entry_class(current_path, folder_path, entry_module_name) do
    entry_class =
      "lsb-block lsb-border-l lsb-py-1 lsb-pl-4 -lsb-ml-1 hover:lsb-border-indigo-600 hover:lsb-text-indigo-600 hover:lsb-border-l-1.5"

    if Enum.join(current_path, "/") == entry_path(folder_path, entry_module_name) do
      entry_class <> " lsb-font-bold lsb-border-indigo-600 lsb-text-indigo-700 lsb-border-l-1.5"
    else
      entry_class <> " lsb-border-slate-200 lsb-text-slate-700"
    end
  end

  defp entry_path(folder_path, module_name) do
    Enum.join(folder_path ++ [Macro.underscore(module_name)], "/")
  end

  defp click_action(_open? = false), do: "open-folder"
  defp click_action(_open? = true), do: "close-folder"

  defp open_folder?(path, _assigns = %{opened_folders: opened_folders}) do
    Enum.member?(opened_folders, path)
  end

  def handle_event("open-folder", %{"path" => path}, socket) do
    {:noreply, assign(socket, :opened_folders, MapSet.put(socket.assigns.opened_folders, path))}
  end

  def handle_event("close-folder", %{"path" => path}, socket) do
    {:noreply,
     assign(socket, :opened_folders, MapSet.delete(socket.assigns.opened_folders, path))}
  end
end
