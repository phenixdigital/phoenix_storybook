defmodule PhxLiveStorybook.PageNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.PageLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine

  def handle_params(params = %{"page" => page}, _uri, socket) do
    entry_module = load_entry_module(page)
    {:noreply, assign(socket, entry_module: entry_module)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, entry_module: "")}
  end

  def render(assigns) do
    ~H"""
    <h2 class="lsb-text-xl lsb-text-blue-400"><%= @entry_module.public_name() %></h2>
    <h2 class="lsb-text-md"><%= @entry_module.public_description() %></h2>
    <%= for {variation_id, variation_assigns} <- @entry_module.public_variations() do %>
      <%= render_component(@entry_module.public_component(), @entry_module.public_function(), Map.put(variation_assigns, :id, variation_id)) %>
      <%= render_component_code(@entry_module.public_function(), variation_assigns) %>
    <% end %>
    """
  end

  defp load_entry_module(page_param) do
    entry_module = page_param |> Enum.map(&Macro.camelize/1) |> Enum.join(".")
    entry_module = :"#{components_module_prefix()}.#{entry_module}"
    Code.ensure_loaded(entry_module)
    entry_module
  end

  defp components_module_prefix do
    apply(storybook_backend(), :components_module_prefix, [])
  end

  defp storybook_backend do
    Application.get_env(:phx_live_storybook, :backend_module)
  end

  defp render_component(module, function, assigns) do
    function_name = function_name(function)

    render_component_markup(module, function, """
    <.#{function_name} #{assigns_markup(assigns)}>
      #{assigns[:do]}
      #{if assigns[:slots], do: for(slot <- assigns[:slots], do: slot)}
    </.#{function_name}>
    """)
  end

  defp render_component_code(function, assigns) do
    props = Map.drop(assigns, [:do, :slots])
    assigns = Map.merge(assigns, %{props: props, function: function})

    ~H"""
    <div class="bg-default-bg p-2 md:p-4 xl:p-8 border">
      <code class="text-sm">
        <div class="-mt-3 mb-4 font-medium">HEEX template</div>
        <div class="mt-2 overflow-x-auto no-scrollbar text-default-txt-secondary">
          <%= raw("<.#{function_name(@function)}") %>

          <%= for {key, val} <- props do %>
            <%= raw("#{key}=#{format_val(val)}") %>
          <% end %>

          <%= if @props[:do] || @props[:slots] do %>
            <%= raw(">") %>
            <br />
            <br />
            <%= if @props[:do] do %>
              <pre class="pl-5">
                <%= @props[:do] %>
              </pre>
            <% end %>
            <%= if @props[:slots] do %>
              <pre class="pl-5">
                <%= for slot <- @props[:slots] do %>
                  <%= slot %>
                <% end %>
              </pre>
            <% end %>
            <%= raw("&lt;/.#{function_name(@function)}>") %>
          <% else %>
            <%= raw("/>") %>
          <% end %>
        </div>
      </code>
    </div>
    """
  end

  defp assigns_markup(assigns) do
    assigns
    |> Map.drop([:do, :slots])
    |> Enum.map_join(" ", fn
      {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
      {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
    end)
  end

  defp render_component_markup(module, function, markup) do
    quoted_code = EEx.compile_string(markup, engine: HTMLEngine)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        aliases: [],
        requires: [Kernel],
        functions: [
          {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]},
          {module, [{function_name(function), 1}]}
        ]
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp function_name(fun), do: Function.info(fun)[:name]

  defp format_val(val) when is_binary(val), do: inspect(val)
  defp format_val(val), do: "{#{inspect(val)}}"
end
