defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.Variation

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

  def handle_params(%{"entry" => entry_path}, _uri, socket) do
    case load_entry_module(socket, entry_path) do
      nil ->
        raise PhxLiveStorybook.EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry_module ->
        {:noreply,
         assign(socket,
           entry_path: entry_path,
           entry_module: entry_module,
           page_title: entry_module.name()
         )}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns = %{entry_module: _module}) do
    ~H"""
    <div class="lsb-space-y-8">
      <div>
        <h2 class="lsb-mt-3 lsb-text-3xl lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
          <%= if icon = @entry_module.icon() do %>
            <i class={"#{icon} lsb-pr-2"}></i>
          <% end %>
          <%= @entry_module.name() %>
        </h2>
        <div class="lsb-mt-4 lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry_module.description() %>
        </div>
      </div>

      <div class="lsb-space-y-12">
        <%= for variation = %Variation{} <- @entry_module.variations() do %>
          <div class="lsb-gap-x-4 lsb-grid lsb-grid-cols-5">

            <!-- Variation description -->
            <div class="lsb-col-span-5 lsb-font-medium lsb-mb-6 lsb-border-b lsb-border-slate-100 lsb-text-lg lsb-leading-7 lsb-text-slate-700">
              <%= if variation.description do %>
                <%= variation.description  %>
              <% else %>
                <%= variation.id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            </div>

            <!-- Variation component preview -->
            <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-2 lsb-flex lsb-items-center lsb-justify-center lsb-p-2">
              <%= @backend_module.render_component(@entry_module, variation.id) %>
            </div>

            <!-- Variation code -->
            <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-3">
              <%= @backend_module.render_code(@entry_module, variation.id) %>
            </div>

          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns), do: ~H""

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
