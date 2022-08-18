defmodule PhxLiveStorybook.Entry.Playground do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_component

  alias Phoenix.{LiveView.JS, PubSub}
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Entry.PlaygroundPreviewLive
  alias PhxLiveStorybook.Rendering.CodeRenderer
  alias PhxLiveStorybook.{Story, StoryGroup}

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_story_attributes()
     |> assign(upper_tab: :preview, lower_tab: :attributes)}
  end

  defp assign_story_attributes(socket = %{assigns: assigns}) do
    case assigns.story do
      story = %Story{} ->
        assign_story_attributes(socket, story, story.id)

      %StoryGroup{id: group_id, stories: [story | _]} ->
        assign_story_attributes(socket, story, [group_id, story.id])

      _ ->
        assign_story_attributes(socket, nil, nil)
    end
  end

  defp assign_story_attributes(socket, nil, nil) do
    assign(socket,
      story_id: nil,
      story: nil,
      playground_attrs: %{},
      playground_block: nil,
      playground_slots: []
    )
  end

  defp assign_story_attributes(socket, story, story_id) do
    assign(socket,
      story: story,
      story_id: story_id,
      playground_attrs: story.attributes,
      playground_block: story.block,
      playground_slots: story.slots
    )
  end

  def render(assigns) do
    ~H"""
    <div class="lsb lsb-flex lsb-flex-col lsb-flex-1">
      <%= render_upper_navigation_tabs(assigns) %>
      <%= render_upper_tab_content(assigns) %>
      <%= render_lower_navigation_tabs(assigns) %>
      <%= render_lower_tab_content(assigns) %>
    </div>
    """
  end

  defp render_upper_navigation_tabs(assigns) do
    ~H"""
    <div class="lsb lsb-border-b lsb-border-gray-200 lsb-mb-6">
      <nav class="lsb -lsb-mb-px lsb-flex lsb-space-x-8">
        <%= for {tab, label, icon} <- [{:preview, "Preview", "fad fa-eye"}, {:code, "Code", "fad fa-code"}] do %>
          <a href="#" phx-click="upper-tab-navigation" phx-value-tab={tab} phx-target={@myself} class={"lsb #{active_link(@upper_tab, tab)} lsb-whitespace-nowrap lsb-py-4 lsb-px-1 lsb-border-b-2 lsb-font-medium lsb-text-sm"}>
            <i class={"lsb #{active_link(@upper_tab, tab)} #{icon} lsb-pr-1"}></i>
            <%= label %>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp render_lower_navigation_tabs(assigns) do
    ~H"""
    <div class="lsb lsb-border-b lsb-border-gray-200 lsb-mt-12 lsb-mb-6">
      <nav class="lsb -lsb-mb-px lsb-flex lsb-space-x-8">
        <%= for {tab, label, icon} <- [{:attributes, "Attributes", "fad fa-list"}] do %>
          <a href="#" phx-click="lower-tab-navigation" phx-value-tab={tab} phx-target={@myself} class={"lsb #{active_link(@lower_tab, tab)} lsb-whitespace-nowrap lsb-py-4 lsb-px-1 lsb-border-b-2 lsb-font-medium lsb-text-sm"}>
            <i class={"lsb  #{active_link(@lower_tab, tab)} #{icon} lsb-pr-1"}></i>
            <%= label %>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp active_link(same_tab, same_tab), do: "lsb lsb-border-indigo-500 lsb-text-indigo-600"

  defp active_link(_current_tab, _tab) do
    "lsb lsb-border-transparent lsb-text-gray-500 hover:lsb-text-gray-700 hover:lsb-border-gray-300"
  end

  defp render_upper_tab_content(assigns = %{upper_tab: _tab}) do
    ~H"""
    <div class={"lsb lsb-relative"}>
      <div class={"lsb lsb-min-h-32 lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-px-2 lsb-bg-white lsb-shadow-sm #{if @upper_tab != :preview, do: "lsb-hidden"}"}>
        <%= if @entry.container() == :iframe do %>
          <iframe
            id={playground_preview_id(@entry)}
            src={live_storybook_path(@socket, :entry_iframe, @entry_path, story_id: inspect(@story_id), playground: true, parent_pid: inspect(self()))}
            height="128"
            class="lsb-w-full lsb-border-0"
            onload="javascript:(function(o){ var height = o.contentWindow.document.body.scrollHeight; if (height > o.style.height) o.style.height=height+'px'; }(this));"
          />
        <% else %>
          <%= live_render @socket, PlaygroundPreviewLive,
            id: playground_preview_id(@entry),
            session: %{
              "entry_path" => @entry_path,
              "story_id" => @story_id,
              "backend_module" => to_string(@backend_module),
              "parent_pid" => self()
            }
          %>
        <% end %>
      </div>
      <%= if @upper_tab == :code do %>
        <div class="lsb lsb-relative lsb-group lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-px-2 lsb-min-h-32 lsb-bg-slate-800 lsb-shadow-sm">
          <div phx-click={JS.dispatch("lsb:copy-code")} class="lsb lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer">
            <i class="lsb fa fa-copy lsb-text-inherit"></i>
          </div>
          <%= CodeRenderer.render_component_code(fun_or_component(@entry), @playground_attrs, @playground_block, @playground_slots) %>
        </div>
      <% end %>
      <%= if @playground_error do %>
        <% error_bg = if @upper_tab == :code, do: "lsb-bg-slate/20", else: "lsb-bg-white/20" %>
        <div class={"lsb lsb-absolute lsb-inset-2 lsb-z-10 lsb-backdrop-blur-lg lsb-text-red-600 #{error_bg} lsb-rounded lsb-flex lsb-flex-col lsb-justify-center lsb-items-center lsb-space-y-2"}>
          <i class="lsb fad fa-xl fa-bomb lsb-text-red-600"></i>
          <span class="lsb lsb-drop-shadow lsb-font-medium">Ohoh, I just crashed!</span>
          <button phx-click="clear-playground-error" class="lsb lsb-inline-flex lsb-items-center lsb-px-2 lsb-py-1 lsb-border lsb-border-transparent lsb-text-xs lsb-font-medium lsb-rounded lsb-shadow-sm lsb-text-white lsb-bg-red-600 hover:lsb-bg-red-700 focus:lsb-outline-none focus:lsb-ring-2 focus:lsb-ring-offset-2 focus:lsb-ring-red-500">
            Dismiss
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_lower_tab_content(assigns = %{lower_tab: :attributes}) do
    ~H"""
    <.form for={:playground} let={f} id={form_id(@entry)} phx-change={"playground-change"} phx-target={@myself} class="lsb-text-gray-600 ">
    <div class="lsb lsb-flex lsb-flex-col lsb-mb-8">
      <div class="lsb lsb-overflow-x-auto md:-lsb-mx-8">
        <div class="lsb lsb-inline-block lsb-min-w-full lsb-py-2 lsb-align-middle md:lsb-px-8">
          <div class="lsb lsb-overflow-hidden lsb-shadow lsb-ring-1 lsb-ring-black lsb-ring-opacity-5 md:lsb-rounded-lg">
            <table class="lsb lsb-min-w-full lsb-divide-y lsb-divide-gray-300">
              <thead class="lsb lsb-bg-gray-50">
                <tr>
                  <%= for header <- ~w(Attribute Type Documentation Default Value) do %>
                    <th scope="col" class="lsb lsb-py-3.5 first:lsb-pl-6 first:lg:lsb-pl-9 lsb-text-left lsb-text-sm lsb-font-semibold lsb-text-gray-900">
                      <%= header %>
                    </th>
                  <% end %>
                </tr>
              </thead>
              <tbody class="lsb lsb-divide-y lsb-divide-gray-200 lsb-bg-white">
                <%= if Enum.empty?(@entry.attributes) do %>
                <tr>
                  <td colspan="5" class="lsb lsb-whitespace-nowrap md:lsb-pr-3 md:lsb-pr-6 lsb-pl-6 md:lsb-pl-9 lsb-py-4 lsb-text-md md:lsb-text-lg lsb-font-medium lsb-text-gray-500 sm:lsb-pl-6 lsb-pt-2 md:lsb-pb-6 md:lsb-pt-4 md:lsb-pb-12 lsb-text-center">
                    <i class="lsb lsb-text-indigo-400 fad fa-xl fa-circle-question lsb-py-4 md:lsb-py-6"></i>
                    <p>In order to use playground, you must define attributes in your <code class="lsb-font-bold"><%= @entry.name %></code> entry.</p>
                  </td>
                </tr>
                <% end %>
                <%= for attr <- @entry.attributes, attr.type not in [:block, :slot] do %>
                  <tr>
                    <td class="lsb lsb-whitespace-nowrap md:lsb-pr-3 md:lsb-pr-6 lsb-pl-6 md:lsb-pl-9 lsb-py-4 lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                      <%= if attr.required do %>
                        <.required_badge/>
                      <% end %>
                      <%= attr.id %>
                    </td>
                    <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500">
                      <.type_badge type={attr.type}/>
                    </td>
                    <td class="lsb lsb-whitespace-pre-line lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500"><%= if attr.doc, do: String.trim(attr.doc) %></td>
                    <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500">
                      <span class="lsb lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs"><%= unless is_nil(attr.default), do: inspect(attr.default) %></span>
                    </td>
                    <td class="lsb lsb-whitespace-nowrap lsb-pr-3 lsb-lsb-py-4 lsb-text-sm lsb-font-medium">
                      <.attr_input form={f} attr_id={attr.id} type={attr.type} playground_attrs={@playground_attrs} options={attr.options} myself={@myself}/>
                    </td>
                  </tr>
                <% end %>
                <%= for attr <- @entry.attributes, attr.type in [:block, :slot] do %>
                  <tr>
                    <td class="lsb lsb-whitespace-nowrap md:lsb-pr-3 md:lsb-pr-6 lsb-pl-6 md:lsb-pl-9 lsb-py-4 lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                      <%= if attr.required do %>
                        <.required_badge/>
                      <% end %>
                      <%= attr.id %>
                    </td>
                    <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500">
                      <.type_badge type={attr.type}/>
                    </td>
                    <td colspan="3" class="lsb lsb-whitespace-pre-line lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500"><%= if attr.doc, do: String.trim(attr.doc) %></td>
                  </tr>
                  <tr class="lsb !lsb-border-t-0">
                    <td colspan="2" class="lsb"></td>
                    <td colspan="3" class="lsb lsb-whitespace-nowrap lsb-pr-3 lsb-pb-3 lsb-text-sm lsb-font-medium lsb-text-gray-900">
                      <pre class="lsb lsb-text-gray-600 lsb-p-2 lsb-border lsb-border-slate-100 lsb-rounded-md lsb-bg-slate-100 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal lsb-flex-1"><%= block_or_slot(assigns, attr) %></pre>
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
    """
  end

  defp render_lower_tab_content(_), do: ""

  defp required_badge(assigns) do
    ~H"""
    <span class="lsb lsb-hidden md:lsb-inline lsb-group lsb-relative -lsb-ml-[1.85em] lsb-pr-2">
      <i class="lsb lsb-text-indigo-400 hover:lsb-text-indigo-600 lsb-cursor-pointer fad fa-circle-dot"></i>
      <span class="lsb lsb-hidden lsb-absolute lsb-top-6 group-hover:lsb-block lsb-z-50 lsb-mx-auto lsb-text-xs lsb-text-indigo-800 lsb-bg-indigo-100 lsb-rounded lsb-px-2 lsb-py-1">
        Required
      </span>
    </span>
    """
  end

  def block_or_slot(assigns, _attr = %{type: :block}) do
    assigns[:playground_block]
  end

  def block_or_slot(assigns, _attr = %{type: :slot, id: slot_id}) do
    slots =
      assigns
      |> Map.get(:playground_slots, [])
      |> Enum.filter(&String.match?(&1, ~r/^<:#{slot_id}[>\s]/))

    if Enum.any?(slots) do
      Enum.join(slots, "\n")
    else
      nil
    end
  end

  defp form_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-form"
  end

  defp playground_preview_id(entry) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  defp type_badge(assigns = %{type: :string}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :atom}) do
    ~H"""
    <span class={"lsb-bg-blue-100 lsb-text-blue-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :boolean}) do
    ~H"""
    <span class={"lsb-bg-slate-500 lsb-text-white #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :integer}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :float}) do
    ~H"""
    <span class={"lsb-bg-teal-100 lsb-text-teal-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :list}) do
    ~H"""
    <span class={"lsb-bg-purple-100 lsb-text-purple-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :block}) do
    ~H"""
    <span class={"lsb-bg-pink-100 lsb-text-pink-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: :slot}) do
    ~H"""
    <span class={"lsb-bg-rose-100 lsb-text-rose-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge(assigns = %{type: _type}) do
    ~H"""
    <span class={"lsb-bg-amber-100 lsb-text-amber-800 #{type_badge_class()}"}><%= type_label(@type) %></span>
    """
  end

  defp type_badge_class do
    "lsb lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs"
  end

  defp type_label(type), do: Macro.to_string(type)

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
    <button type="button" phx-click={on_toggle_click(f, attr_id, value)} class={"lsb #{bg_class} lsb-relative lsb-inline-flex lsb-flex-shrink-0 lsb-p-0 lsb-h-6 lsb-w-11 lsb-border-2 lsb-border-transparent lsb-rounded-full lsb-cursor-pointer lsb-transition-colors lsb-ease-in-out lsb-duration-200 focus:lsb-outline-none focus:lsb-ring-2 focus:lsb-ring-offset-2 focus:lsb-ring-indigo-500"} phx-target={@myself} role="switch">
      <%= hidden_input(f, attr_id, value: value) %>
      <span class={"lsb #{translate_class} lsb-form-input lsb-p-0 lsb-border-0 lsb-pointer-events-none lsb-inline-block lsb-h-5 lsb-w-5 lsb-rounded-full lsb-bg-white lsb-shadow lsb-transform lsb-ring-0 lsb-transition lsb-ease-in-out lsb-duration-200"}></span>
    </button>
    """
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           type: type,
           options: nil,
           playground_attrs: playground_attrs
         }
       )
       when type in [:integer, :float] do
    step = if type == :integer, do: 1, else: 0.01

    ~H"""
    <%= number_input(f, attr_id, value: Map.get(playground_attrs, attr_id), step: step, class: "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500  sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md") %>
    """
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           type: :integer,
           options: min..max,
           playground_attrs: playground_attrs
         }
       ) do
    ~H"""
    <%= number_input(f, attr_id, value: Map.get(playground_attrs, attr_id), min: min, max: max, class: "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md") %>
    """
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           type: :string,
           options: nil,
           playground_attrs: playground_attrs
         }
       ) do
    ~H"""
    <%= text_input(f, attr_id, value: Map.get(playground_attrs, attr_id), class: "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md") %>
    """
  end

  defp attr_input(
         assigns = %{
           form: f,
           attr_id: attr_id,
           type: _type,
           options: nil,
           playground_attrs: playground_attrs
         }
       ) do
    value = Map.get(playground_attrs, attr_id)
    value = if is_nil(value), do: "", else: inspect(value)

    ~H"""
    <%= text_input(f, attr_id, value: value, disabled: true, class: "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md") %>
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
    options = [nil | Enum.map(options, &to_string/1)]

    ~H"""
    <%= select(f, attr_id, options, value: Map.get(playground_attrs, attr_id),
      class: "lsb lsb-form-select lsb-mt-1 lsb-block lsb-w-full lsb-pl-3 lsb-pr-10 lsb-py-2 lsb-text-base lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-text-sm lsb-rounded-md") %>
    """
  end

  defp on_toggle_click(form, attr_id, value) do
    JS.set_attribute({"value", to_string(!value)}, to: "##{form.id}_#{attr_id}")
    |> JS.push("playground-toggle", value: %{toggled: [attr_id, !value]})
  end

  defp fun_or_component(%ComponentEntry{type: :live_component, component: component}),
    do: component

  defp fun_or_component(%ComponentEntry{type: :component, function: function}),
    do: function

  def handle_event("upper-tab-navigation", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :upper_tab, String.to_atom(tab))}
  end

  def handle_event("lower-tab-navigation", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :lower_tab, String.to_atom(tab))}
  end

  def handle_event("playground-change", %{"playground" => params}, socket = %{assigns: assigns}) do
    entry = assigns.entry

    playground_attrs =
      for {key, value} <- params, key = String.to_atom(key), reduce: assigns.playground_attrs do
        acc ->
          attr_definition = Enum.find(entry.attributes, &(&1.id == key))

          if (is_nil(value) || value == "") and !attr_definition.required do
            Map.delete(acc, key)
          else
            Map.put(acc, key, cast_value(entry, key, value))
          end
      end

    send_attributes(playground_attrs)

    {:noreply, assign(socket, playground_attrs: playground_attrs)}
  end

  def handle_event(
        "playground-toggle",
        %{"toggled" => [key, value]},
        socket = %{assigns: assigns}
      ) do
    playground_attrs = Map.put(assigns.playground_attrs, String.to_atom(key), value)
    send_attributes(playground_attrs)
    {:noreply, assign(socket, :playground_attrs, playground_attrs)}
  end

  defp send_attributes(attributes) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "playground",
      {:new_attributes, self(), attributes}
    )
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
