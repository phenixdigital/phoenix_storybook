defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer}
  alias PhxLiveStorybook.Variation

  def mount(_params, session, socket) do
    {:ok, assign(socket, backend_module: session["backend_module"])}
  end

  def handle_params(_params = %{"entry" => entry_path}, _uri, socket) do
    case load_entry_module(socket, entry_path) do
      nil ->
        raise PhxLiveStorybook.EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry_module ->
        {:noreply,
         assign(socket,
           entry_path: entry_path,
           entry_module: entry_module,
           page_title: entry_module.public_name()
         )}
    end
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def render(assigns = %{entry_module: _module}) do
    ~H"""
    <div class="lsb-space-y-8">
      <div>
        <h2 class="lsb-mt-3 lsb-text-3xl lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
          <%= if icon = @entry_module.public_icon() do %>
            <i class={"#{icon} lsb-pr-2"}></i>
          <% end %>
          <%= @entry_module.public_name() %>
        </h2>
        <div class="lsb-mt-4 lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry_module.public_description() %>
        </div>
      </div>

      <div class="lsb-space-y-12">
        <%= for variation = %Variation{} <- @entry_module.public_variations() do %>
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
              <%= if @entry_module.live_component?() do %>
                <%= ComponentRenderer.render_live_component(@entry_module.public_component(), variation) %>
              <% else %>
                <%= ComponentRenderer.render_component(@entry_module.public_component(), @entry_module.public_function(), variation) %>
              <% end %>
            </div>

            <!-- Variation code -->
            <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-3">
              <%= if @entry_module.live_component?() do %>
                <%= CodeRenderer.render_live_component_code(@entry_module.public_component(), variation) %>
              <% else %>
                <%= CodeRenderer.render_component_code(@entry_module.public_function(), variation) %>
              <% end %>
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
    socket.assigns.backend_module.config(
      :entries_module_prefix,
      socket.assigns.backend_module
    )
  end
end
