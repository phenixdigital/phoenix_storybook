defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.Components.{CodeRenderer, ComponentRenderer, Variation}

  def handle_params(_params = %{"entry" => entry}, _uri, socket) do
    entry_module = load_entry_module(socket, entry)
    {:noreply, assign(socket, entry_module: entry_module)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns = %{entry_module: _module}) do
    ~H"""
    <div class="lsb-space-y-8">
      <div>
        <h2 class="lsb-text-xl lsb-text-blue-400"><%= @entry_module.public_name() %></h2>
        <h2 class="lsb-text-md"><%= @entry_module.public_description() %></h2>
      </div>

      <div class="lsb-space-y-12">
        <%= for variation = %Variation{} <- @entry_module.public_variations() do %>
          <div class="lsb-space-y-4">
            <%= ComponentRenderer.render_component(@entry_module.public_component(), @entry_module.public_function(), variation) %>
            <%= CodeRenderer.render_component_code(@entry_module.public_function(), variation) %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp load_entry_module(socket, entry_param) do
    entry_module = entry_param |> Enum.map(&Macro.camelize/1) |> Enum.join(".")
    entry_module = :"#{components_module_prefix(socket)}.#{entry_module}"
    Code.ensure_loaded(entry_module)
    entry_module
  end

  defp components_module_prefix(socket) do
    socket.private.connect_info.private.backend_module.config(:components_module_prefix)
  end

end
