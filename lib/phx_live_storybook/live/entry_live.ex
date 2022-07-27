defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryTabNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryLive do
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.{EntryNotFound, EntryTabNotFound}
  alias PhxLiveStorybook.Variation

  @tabs [
    {:variations, "Variations", "far fa-eye"},
    {:documentation, "Documentation", "far fa-book"},
    {:source, "Source", "far fa-file-code"}
  ]

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"],
       tabs: @tabs,
       tab: :variations
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
           entry_path: entry_path,
           entry_module: entry_module,
           page_title: entry_module.name(),
           tab: params |> Map.get("tab", "variations") |> String.to_atom()
         )}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns = %{entry_module: _module}) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pb-24" id="entry-live" phx-hook="EntryHook">
      <div>
        <div class="lsb-flex lsb-mt-5">
          <h2 class="lsb-flex-1 lsb-text-3xl lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
            <%= if icon = @entry_module.icon() do %>
              <i class={"#{icon} lsb-pr-2"}></i>
            <% end %>
            <%= @entry_module.name() %>
          </h2>

          <%= render_navigation_toggle(assigns) %>
        </div>
        <div class="lsb-mt-4 lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry_module.description() %>
        </div>
      </div>

      <%= render_tab_content(assigns) %>
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp render_navigation_toggle(assigns) do
    ~H"""
    <div class="lsb-rounded-lg lsb-flex lsb-border lsb-bg-slate-100 lsb-hover:lsb-bg-slate-200 lsb-h-10 lsb-text-sm lsb-font-medium">
      <%= for {tab, label, icon} <- @tabs do %>
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

  defp render_tab_content(assigns = %{tab: :variations}) do
    ~H"""
    <div class="lsb-space-y-12">
      <%= for variation = %Variation{} <- @entry_module.variations() do %>
        <div id={anchor_id(variation)} class="lsb-gap-x-4 lsb-grid lsb-grid-cols-5">

          <!-- Variation description -->
          <div class="lsb-col-span-5 lsb-font-medium hover:lsb-font-semibold lsb-mb-6 lsb-border-b lsb-border-slate-100 lsb-text-lg lsb-leading-7 lsb-text-slate-700 lsb-group">
            <%= link to: "##{anchor_id(variation)}", class: "entry-anchor-link" do %>
              <i class="fal fa-link hidden group-hover:lsb-inline -lsb-ml-8 lsb-pr-1 lsb-text-slate-400"></i>
              <%= if variation.description do %>
                <%= variation.description  %>
              <% else %>
                <%= variation.id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            <% end %>
          </div>

          <!-- Variation component preview -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-2 lsb-flex lsb-items-center lsb-justify-center lsb-p-2">
            <%= @backend_module.render_component(@entry_module, variation.id) %>
          </div>

          <!-- Variation code -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-3 lsb-group lsb-relative">
            <div class="copy-code-btn lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer">
              <i class="fa fa-copy"></i>
            </div>
            <%= @backend_module.render_code(@entry_module, variation.id) %>
          </div>

        </div>
      <% end %>
    </div>
    """
  end

  defp render_tab_content(assigns = %{tab: :documentation}) do
    ~H"""
    <div class="lsb-w-full lsb-text-center lsb-text-slate-400 lsb-pt-20 lsb-px-40">
      <i class="hover:lsb-text-indigo-400 fas fa-traffic-cone fa-5x fa-bounce" style="--fa-animation-iteration-count: 2;"></i>
      <h2 class="lsb-mt-8 lsb-text-lg">Coming soon</h2>
      <p class="lsb-text-left lsb-pt-12 lsb-text-slate-500">
        Here, you'll soon be able to explore your component properties, see their related
        documentation and experiment with them in an interactive playground.
        <br/><br/>
        This will most likely rely on <code>phoenix_live_view 0.18.0</code> declarative assigns feature.
      </p>
    </div>
    """
  end

  defp render_tab_content(assigns = %{tab: :source}) do
    ~H"""
    <%= @backend_module.render_source(@entry_module) %>
    """
  end

  defp render_tab_content(_assigns = %{tab: tab}),
    do: raise(EntryTabNotFound, "unknown entry tab #{inspect(tab)}")

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

  defp anchor_id(%Variation{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end
end
