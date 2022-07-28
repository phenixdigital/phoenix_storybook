defmodule PhxLiveStorybook.EntryLive do
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.Entry.{ComponentEntryLive, PageEntryLive}
  alias PhxLiveStorybook.EntryNotFound

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"]
     )}
  end

  def handle_params(params, _uri, socket) when params == %{} do
    case first_component_entry_path(socket) do
      nil ->
        {:noreply, socket}

      entry ->
        {:noreply, push_patch(socket, to: live_storybook_path(socket, :entry, entry))}
    end
  end

  def handle_params(params = %{"entry" => entry_path}, _uri, socket) do
    case load_entry_module(socket, entry_path) do
      nil ->
        raise EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry_module ->
        {:noreply,
         assign(socket,
           entry_type: entry_module.storybook_type(),
           entry_path: entry_path,
           entry_module: entry_module,
           page_title: entry_module.name(),
           tab: current_tab(params, entry_module)
         )}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp current_tab(params, entry_module) do
    case Map.get(params, "tab") do
      nil ->
        case entry_module.storybook_type() do
          type when type in [:component, :live_component] -> ComponentEntryLive.default_tab()
          :page -> PageEntryLive.default_tab(entry_module)
        end

      tab ->
        String.to_atom(tab)
    end
  end

  def render(assigns = %{entry_module: _module}) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pb-24" id="entry-live" phx-hook="EntryHook">
      <div>
        <div class="lsb-flex lsb-mt-5 lsb-items-center">
          <h2 class="lsb-flex-1 lsb-text-3xl lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
            <%= if icon = @entry_module.icon() do %>
              <i class={"#{icon} lsb-pr-2"}></i>
            <% end %>
            <%= @entry_module.name() %>
          </h2>

          <%=  @entry_type |> navigation_tabs(assigns) |> render_navigation_tabs(assigns) %>
        </div>
        <div class="lsb-mt-4 lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry_module.description() %>
        </div>
      </div>

      <%= render_content(@entry_type, assigns) %>
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp navigation_tabs(type, _assigns) when type in [:component, :live_component] do
    ComponentEntryLive.navigation_tabs()
  end

  defp navigation_tabs(:page, assigns) do
    PageEntryLive.navigation_tabs(assigns)
  end

  defp render_navigation_tabs([], assigns), do: ~H""

  defp render_navigation_tabs(tabs, assigns) do
    ~H"""
    <div class="lsb-rounded-lg lsb-flex lsb-border lsb-bg-slate-100 lsb-hover:lsb-bg-slate-200 lsb-h-10 lsb-text-sm lsb-font-medium">
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
    </div>
    """
  end

  defp render_content(type, assigns) when type in [:component, :live_component] do
    ComponentEntryLive.render(assigns)
  end

  defp render_content(:page, assigns) do
    PageEntryLive.render(assigns)
  end

  defp active_link(same, same), do: ""

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

  defp load_entry_module(socket, entry_param) do
    entry_module = Enum.map_join(entry_param, ".", &Macro.camelize/1)
    entry_module = :"#{entries_module_prefix(socket)}.#{entry_module}"

    case Code.ensure_loaded(entry_module) do
      {:module, ^entry_module} -> entry_module
      _ -> nil
    end
  end

  defp entries_module_prefix(socket) do
    config(socket, :entries_module_prefix, socket.assigns.backend_module)
  end

  defp config(socket, key, default) do
    socket.assigns.backend_module.config(key, default)
  end

  defp first_component_entry_path(socket) do
    socket.assigns.backend_module.path_to_first_leaf_entry()
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
