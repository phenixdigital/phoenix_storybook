defmodule PhxLiveStorybook.Sidebar do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  def mount(socket) do
    {:ok, assign(socket, :opened_folders, MapSet.new())}
  end

  def update(assigns = %{current_path: current_path}, socket) do
    root_path = live_storybook_path(socket, :home)
    current_path = if current_path, do: [root_path | current_path], else: [root_path]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       opened_folders: set_opened_folders_from_path(socket.assigns.opened_folders, current_path),
       root_path: root_path,
       root_entries: assigns.backend_module.storybook_entries(),
       current_path: current_path
     )}
  end

  defp set_opened_folders_from_path(opened_folders, path) do
    {opened_folders, _} =
      for path_item <- Enum.slice(path, 0..2), reduce: {opened_folders, nil} do
        {opened_folders, path_acc} ->
          path = if path_acc, do: "#{path_acc}/#{path_item}", else: path_item
          {MapSet.put(opened_folders, path), path}
      end

    opened_folders
  end

  def render(assigns) do
    ~H"""
    <section
      class="lsb-fixed lsb-text-sm lsb-w-60 lsb-h-screen lsb-flex lsb-flex-col lsb-flex-grow lsb-bg-slate-50 lsb-pt-4 lsb-px-4 lsb-overflow-y-auto"
    >
      <nav class="lsb-flex-1 xl:lsb-sticky xl:lsb-top-[4.5rem]">
        <%= render_entries(assign(assigns, entries: @root_entries, folder_path: [@root_path])) %>
      </nav>
    </section>
    """
  end

  defp render_entries(assigns) do
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
                  <%= heroicon(:chevron_down, "lsb-h-4 lsb-w-4 lsb-mr-2 lsb-text-slate-400 group-hover:lsb-text-indigo-600") %>
                <% else %>
                  <%= heroicon(:chevron_right, "lsb-h-4 lsb-w-4 lsb-mr-2 lsb-text-slate-400 group-hover:lsb-text-indigo-600") %>
                <% end %>
                <%= String.capitalize(folder_name) %>
              </div>
              <%= if open_folder? do %>
                <%= render_entries(assign(assigns, entries: sub_entries, folder_path: @folder_path ++ [folder_name])) %>
              <% end %>

            <% %ComponentEntry{name: name, module_name: module_name} -> %>
              <div class={entry_class(@current_path, @folder_path, module_name)}>
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
    Enum.any?(opened_folders, fn folder ->
      folder == path
    end)
  end

  def handle_event("open-folder", %{"path" => path}, socket) do
    {:noreply, assign(socket, :opened_folders, MapSet.put(socket.assigns.opened_folders, path))}
  end

  def handle_event("close-folder", %{"path" => path}, socket) do
    {:noreply,
     assign(socket, :opened_folders, MapSet.delete(socket.assigns.opened_folders, path))}
  end
end
