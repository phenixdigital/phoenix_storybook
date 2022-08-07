defmodule PhxLiveStorybook.Entry.Playground do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias Phoenix.LiveView.JS
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Entry.PlaygroundPreview

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       playground_attrs: default_attrs(assigns.entry),
       playground_sequence: 0
     )}
  end

  defp default_attrs(%ComponentEntry{attributes: attributes}) do
    for attr <- attributes, value = attr.init, !is_nil(value), into: %{} do
      {attr.id, value}
    end
  end

  defp default_attrs(_entry), do: nil

  def render(assigns) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pt-8">
      <!-- Component playground -->
      <.live_component module={PlaygroundPreview} id={"#{Macro.underscore(@entry.module)}-playground-#{@playground_sequence}"}
        entry={@entry} attrs={@playground_attrs}
      />

      <!-- Component properties -->
      <.form for={:playground} let={f} id={form_id(@entry)} phx-change={"playground-change"} phx-target={@myself}>
        <div class="lsb-mt-8 lsb-flex lsb-flex-col">
          <div class="-lsb-my-2 -lsb-mx-4 lsb-overflow-x-auto md:-lsb-mx-8">
            <div class="lsb-inline-block lsb-min-w-full lsb-py-2 lsb-align-middle md:lsb-px-8">
              <div class="lsb-overflow-hidden lsb-shadow lsb-ring-1 lsb-ring-black lsb-ring-opacity-5 md:lsb-rounded-lg">
                <table class="lsb-min-w-full lsb-divide-y lsb-divide-gray-300">
                  <thead class="lsb-bg-gray-50">
                    <tr>
                      <%= for header <- ~w(Attribute Type Documentation Default Value) do %>
                        <th scope="col" class="lsb-py-3.5 lsb-px-3 md:lsb-px-6 first:lsb-pl-6 first:lg:lsb-pl-9 lsb-text-left lsb-text-sm lsb-font-semibold lsb-text-gray-900">
                          <%= header %>
                        </th>
                      <% end %>
                    </tr>
                  </thead>
                  <tbody class="lsb-divide-y lsb-divide-gray-200 lsb-bg-white">
                    <%= for attr <- @entry.attributes do %>
                      <tr>
                        <td class="lsb-whitespace-nowrap lsb-pr-3 md:lsb-pr-6 lsb-pl-6 md:lsb-pl-9 lsb-py-4 lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                          <%= if attr.required do %>
                            <span class="lsb-hidden md:lsb-inline lsb-group lsb-relative -lsb-ml-[1.85em] lsb-pr-2">
                              <i class="lsb-text-indigo-400 hover:lsb-text-indigo-600 lsb-cursor-pointer fad fa-circle-dot"></i>
                              <span class="lsb-hidden lsb-absolute lsb-top-6 group-hover:lsb-block lsb-z-50 lsb-mx-auto lsb-text-xs lsb-text-indigo-800 lsb-bg-indigo-100 lsb-rounded lsb-px-2 lsb-py-1">
                                Required
                              </span>
                            </span>
                          <% end %>

                          <%= attr.id %>
                        </td>
                        <td class="lsb-whitespace-nowrap lsb-px-3 lg:lsb-px-6 lsb-py-4 lsb-text-sm lsb-text-gray-500">
                          <.type_badge type={attr.type}/>
                        </td>
                        <td class="lsb-whitespace-pre-line lsb-px-3 lg:lsb-px-6 lsb-py-4 lsb-text-sm lsb-text-gray-500"><%=String.trim(attr.doc)%></td>
                        <td class="lsb-whitespace-nowrap lsb-px-3 lg:lsb-px-6 lsb-py-4 lsb-text-sm lsb-text-gray-500">
                          <span class="lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs"><%= attr.default %></span>
                        </td>
                        <td class="lsb-whitespace-nowrap lsb-lsb-py-4 lsb-pl-3 lsb-pr-4  lsb-text-sm lsb-font-medium sm:lsb-pr-6">
                          <.attr_input form={f} attr_id={attr.id} type={attr.type} playground_attrs={@playground_attrs} options={attr.options} myself={@myself}/>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  defp form_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-form"
  end

  defp type_badge(assigns = %{type: :string}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :atom}) do
    ~H"""
    <span class={"lsb-bg-blue-100 lsb-text-blue-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :boolean}) do
    ~H"""
    <span class={"lsb-bg-slate-500 lsb-text-white #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :integer}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :float}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :list}) do
    ~H"""
    <span class={"lsb-bg-teal-100 lsb-text-teal-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: _type}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge_class do
    "lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs"
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           type: :boolean,
           playground_attrs: playground_attrs
         }
       ) do
    value = Map.get(playground_attrs, attr_id)
    bg_class = if value, do: "lsb-bg-indigo-600", else: "lsb-bg-gray-200"
    translate_class = if value, do: "lsb-translate-x-5", else: "lsb-translate-x-0"

    ~H"""
    <button type="button" phx-click={on_toggle_click(f, attr_id, value)} class={"#{bg_class} lsb-relative lsb-inline-flex lsb-flex-shrink-0 lsb-h-6 lsb-w-11 lsb-border-2 lsb-border-transparent lsb-rounded-full lsb-cursor-pointer lsb-transition-colors lsb-ease-in-out lsb-duration-200 focus:lsb-outline-none focus:lsb-ring-2 focus:lsb-ring-offset-2 focus:lsb-ring-indigo-500"} phx-target={@myself} role="switch">
      <%= hidden_input(f, attr_id, value: value) %>
      <span class={"#{translate_class} lsb-pointer-events-none lsb-inline-block lsb-h-5 lsb-w-5 lsb-rounded-full lsb-bg-white lsb-shadow lsb-transform lsb-ring-0 lsb-transition lsb-ease-in-out lsb-duration-200"}></span>
    </button>
    """
  end

  defp attr_input(
         assigns = %{form: f, attr_id: attr_id, options: nil, playground_attrs: playground_attrs}
       ) do
    ~H"""
    <%= text_input(f, attr_id, value: Map.get(playground_attrs, attr_id), class: "lsb-max-w-lg lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-max-w-xs sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md") %>
    """
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           options: options,
           playground_attrs: playground_attrs
         }
       ) do
    ~H"""
    <%= select(f, attr_id, [nil | options], value: Map.get(playground_attrs, attr_id),
      class: "lsb-mt-1 lsb-block lsb-w-full lsb-pl-3 lsb-pr-10 lsb-py-2 lsb-text-base lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-text-sm lsb-rounded-md") %>
    """
  end

  defp on_toggle_click(form, attr_id, value) do
    JS.set_attribute({"value", to_string(!value)}, to: "##{form.id}_#{attr_id}")
    |> JS.push("playground-toggle", value: %{toggled: [attr_id, !value]})
  end

  def handle_event("playground-change", %{"playground" => params}, socket = %{assigns: assigns}) do
    entry = assigns.entry

    playground_attrs =
      for {key, value} <- params, key = String.to_atom(key), reduce: assigns.playground_attrs do
        acc ->
          if is_nil(value) || value == "" do
            Map.delete(acc, key)
          else
            Map.put(acc, key, cast_value(entry, key, value))
          end
      end

    {:noreply,
     assign(socket,
       playground_attrs: playground_attrs,
       playground_sequence: assigns.playground_sequence + 1
     )}
  end

  def handle_event(
        "playground-toggle",
        %{"toggled" => [key, value]},
        socket = %{assigns: assigns}
      ) do
    playground_attrs = Map.put(assigns.playground_attrs, String.to_atom(key), value)
    {:noreply, assign(socket, :playground_attrs, playground_attrs)}
  end

  defp cast_value(%ComponentEntry{attributes: attributes}, attr_id, value) do
    attr = Enum.find(attributes, &(&1.id == attr_id))

    case attr.type do
      :atom -> String.to_atom(value)
      :boolean -> String.to_atom(value)
      _ -> value
    end
  end
end
