defmodule PhoenixStorybook.Story.Playground do
  @moduledoc false
  use PhoenixStorybook.Web, :live_component

  alias Phoenix.{LiveView.JS, PubSub}
  alias PhoenixStorybook.Rendering.{CodeRenderer, RenderingContext}
  alias PhoenixStorybook.Story.PlaygroundPreviewLive
  alias PhoenixStorybook.TemplateHelpers
  alias PhoenixStorybook.Stories.{Attr, Slot, Variation, VariationGroup}

  import PhoenixStorybook.NavigationHelpers

  def mount(socket) do
    {:ok, assign(socket, event_logs: [], event_logs_unread: 0)}
  end

  def update(%{new_event: event}, socket) do
    {:ok,
     socket
     |> update(:event_logs, &[event | &1])
     |> update(:event_logs_unread, fn
       _unread, %{lower_tab: :events} -> 0
       unread, _assigns -> unread + 1
     end)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_variations()
     |> assign_new_variations_attributes(assigns)
     |> assign_new_template_attributes(assigns)
     |> assign_playground_fields()
     |> assign_playground_slots()
     |> assign_variation_id()
     |> assign_new(:upper_tab, fn -> :preview end)
     |> assign_new(:lower_tab, fn -> :attributes end)}
  end

  defp assign_variation_id(socket) do
    case Map.get(socket.assigns, :variation) do
      nil -> assign(socket, :variation_id, nil)
      v -> assign(socket, :variation_id, v.id)
    end
  end

  defp assign_variations(socket = %{assigns: assigns}) do
    case assigns.variation do
      variation = %Variation{} ->
        assign_variations(socket, :single, [variation])

      %VariationGroup{id: group_id, variations: variations} ->
        assign_variations(socket, group_id, variations)

      _ ->
        assign(socket, variations: [], variation_id: nil)
    end
  end

  defp assign_variations(socket, group_id, variations) do
    variations =
      for variation <- variations do
        variation_id = {group_id, variation.id}

        variation
        |> Map.take([:attributes, :let, :slots, :template])
        |> Map.put(:id, variation_id)
        |> put_in([:attributes, :theme], socket.assigns[:theme])
      end

    assign(socket, variations: variations)
  end

  # new_attributes may be passed by parent (LiveView) send_update.
  # It happens whenever parent is notified some component assign has been
  # updated by the component itself.
  defp assign_new_variations_attributes(socket, assigns) do
    new_attributes = Map.get(assigns, :new_variations_attributes, %{})

    variations =
      for variation <- socket.assigns.variations do
        variation_id = variation.id

        case Map.get(new_attributes, variation_id) do
          nil -> variation
          new_attrs -> update_variation_attributes(variation, new_attrs)
        end
      end

    assign(socket, variations: variations)
  end

  defp assign_new_template_attributes(socket, assigns) do
    current_attributes = Map.get(socket.assigns, :template_attributes, %{})
    new_attributes = Map.get(assigns, :new_template_attributes, %{})

    template_attributes =
      for {{_group_id, variation_id}, new_variation_attrs} <- new_attributes,
          reduce: current_attributes do
        acc ->
          current_attrs = Map.get(acc, variation_id, %{})
          new_variation_attrs = Map.merge(current_attrs, new_variation_attrs)
          Map.put(acc, variation_id, new_variation_attrs)
      end

    assign(socket, template_attributes: template_attributes)
  end

  defp assign_playground_fields(socket = %{assigns: %{story: story, variations: variations}}) do
    fields =
      for attr = %Attr{id: attr_id} <- story.merged_attributes(), reduce: %{} do
        acc ->
          attr_values =
            for %{id: variation_id, attributes: attrs} <- variations do
              if attr_id == :id do
                TemplateHelpers.unique_variation_id(story, variation_id)
              else
                Map.get(attrs, attr_id)
              end
            end

          field =
            case Enum.uniq(attr_values) do
              [] -> nil
              [val] -> val
              _ -> :locked
            end

          Map.put(acc, attr.id, field)
      end

    assign(socket, :fields, fields)
  end

  defp assign_playground_slots(socket = %{assigns: %{story: story, variations: variations}}) do
    slots =
      for %Slot{id: slot_id} <- story.merged_slots(), reduce: %{} do
        acc ->
          slots =
            for variation <- variations do
              for(slot <- variation.slots, matching_slot?(slot_id, slot), do: slot)
              |> Enum.map_join("\n", &String.trim/1)
              |> String.trim()
            end

          slot =
            if slots |> Enum.uniq() |> length() == 1 do
              hd(slots)
            else
              :locked
            end

          Map.put(acc, slot_id, slot)
      end

    assign(socket, :slots, slots)
  end

  defp matching_slot?(:inner_block, slot) do
    not Regex.match?(~r|<:\w+.*|s, slot)
  end

  defp matching_slot?(slot_id, slot) do
    Regex.match?(~r|<:#{slot_id}.*</:#{slot_id}>|s, slot)
  end

  def render(assigns) do
    ~H"""
    <div id="playground" class="lsb lsb-flex lsb-flex-col lsb-flex-1">
      <%= render_upper_navigation_tabs(assigns) %>
      <%= render_upper_tab_content(assigns) %>
      <%= render_lower_navigation_tabs(assigns) %>
      <%= render_lower_tab_content(assigns) %>
    </div>
    """
  end

  defp render_upper_navigation_tabs(assigns) do
    assigns = assign(assigns, tabs: [{:preview, "Preview", "eye"}, {:code, "Code", "code"}])

    ~H"""
    <div class="lsb lsb-border-b lsb-border-gray-200 lsb-mb-6">
      <nav class="lsb -lsb-mb-px lsb-flex lsb-space-x-8">
        <%= for {tab, label, icon} <- @tabs do %>
          <a
            href="#"
            phx-click="upper-tab-navigation"
            phx-value-tab={tab}
            phx-target={@myself}
            class={[
              active_link(@upper_tab, tab),
              "lsb lsb-whitespace-nowrap lsb-py-4 lsb-px-1 lsb-border-b-2 lsb-font-medium lsb-text-sm"
            ]}
          >
            <.fa_icon
              style={:duotone}
              name={icon}
              class={"lsb-pr-1 #{active_link(@upper_tab, tab)}"}
              plan={@fa_plan}
            />
            <%= label %>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp render_lower_navigation_tabs(assigns) do
    ~H"""
    <div class="lsb lsb-border-b lsb-border-gray-200 lsb-mt-6 md:lsb-mt-12 lsb-mb-4">
      <nav class="lsb -lsb-mb-px lsb-flex lsb-space-x-8">
        <%= for {tab, label, icon} <- [{:attributes, "Attributes", "table"}, {:events, "Event logs", "list-timeline"}] do %>
          <a
            href="#"
            phx-click="lower-tab-navigation"
            phx-value-tab={tab}
            phx-target={@myself}
            class={"lsb #{active_link(@lower_tab, tab)} lsb-whitespace-nowrap lsb-py-4 lsb-px-1 lsb-border-b-2 lsb-font-medium lsb-text-sm"}
          >
            <.fa_icon
              style={:duotone}
              name={icon}
              class={"lsb-pr-1 #{active_link(@lower_tab, tab)}"}
              plan={@fa_plan}
            />
            <%= label %>
            <%= event_counter(tab, @event_logs_unread) %>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp active_link(same_tab, same_tab), do: "lsb-border-indigo-500 lsb-text-indigo-600"

  defp active_link(_current_tab, _tab) do
    "lsb-border-transparent lsb-text-gray-500 hover:lsb-text-gray-700 hover:lsb-border-gray-300"
  end

  defp event_counter(:events, count) when count > 0, do: "(#{count})"
  defp event_counter(_, _), do: nil

  defp render_upper_tab_content(assigns = %{upper_tab: _tab}) do
    ~H"""
    <div class="lsb lsb-relative">
      <div class={[
        "lsb lsb-min-h-32 lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-bg-white lsb-shadow-sm",
        if(@upper_tab != :preview, do: "lsb-hidden"),
        if(@story.container() != :iframe, do: "lsb-px-2")
      ]}>
        <%= if @story.container() == :iframe do %>
          <iframe
            id={playground_preview_id(@story)}
            src={
              path_to_iframe(@socket, @root_path, @story_path,
                variation_id: to_string(@variation_id),
                theme: to_string(@theme),
                playground: true,
                topic: @topic
              )
            }
            height="128"
            class="lsb-w-full lsb-border-0"
            onload="javascript:(function(o){ var height = o.contentWindow.document.body.scrollHeight; if (height > o.style.height) o.style.height=height+'px'; }(this));"
          />
        <% else %>
          <%= live_render(@socket, PlaygroundPreviewLive,
            id: playground_preview_id(@story),
            session: %{
              "story" => @story,
              "variation_id" => to_string(@variation_id),
              "theme" => to_string(@theme),
              "topic" => "playground-#{inspect(self())}",
              "backend_module" => @backend_module
            },
            container: {:div, style: "height: 100%; width: 100%;"}
          ) %>
        <% end %>
      </div>
      <%= if @upper_tab == :code do %>
        <div class="lsb lsb-relative lsb-group lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-px-2 lsb-min-h-32 lsb-bg-slate-800 lsb-shadow-sm">
          <div
            phx-click={JS.dispatch("lsb:copy-code")}
            class="lsb lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer"
          >
            <.fa_icon name="copy" class="lsb-text-inherit" plan={@fa_plan} />
          </div>
          <.playground_code
            story={@story}
            variation={@variation}
            variations={@variations}
            backend_module={@backend_module}
          />
        </div>
      <% end %>
      <%= if @playground_error do %>
        <% error_bg = if @upper_tab == :code, do: "lsb-bg-slate/20", else: "lsb-bg-white/20" %>
        <div class={"lsb lsb-absolute lsb-inset-2 lsb-z-10 lsb-backdrop-blur-lg lsb-text-red-600 #{error_bg} lsb-rounded lsb-flex lsb-flex-col lsb-justify-center lsb-items-center lsb-space-y-2"}>
          <.fa_icon style={:duotone} name="bomb" class="fa-xl lsb-text-red-600" plan={@fa_plan} />
          <span class="lsb lsb-drop-shadow lsb-font-medium">Ohoh, I just crashed!</span>
          <button
            phx-click="clear-playground-error"
            class="lsb lsb-inline-flex lsb-items-center lsb-px-2 lsb-py-1 lsb-border lsb-border-transparent lsb-text-xs lsb-font-medium lsb-rounded lsb-shadow-sm lsb-text-white lsb-bg-red-600 hover:lsb-bg-red-700 focus:lsb-outline-none focus:lsb-ring-2 focus:lsb-ring-offset-2 focus:lsb-ring-red-500"
          >
            Dismiss
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp playground_code(assigns) do
    variation_attributes = for v <- assigns.variations, into: %{}, do: {v.id, v.attributes}

    RenderingContext.build(
      assigns.backend_module,
      assigns.story,
      assigns.variation,
      variation_attributes
    )
    |> CodeRenderer.render()
  end

  defp render_lower_tab_content(assigns = %{lower_tab: :events}) do
    ~H"""
    <div
      id={playground_event_logs_id(@story)}
      class="lsb lsb-flex lsb-flex-col lsb-grow lsb-py-2 lsb-relative"
    >
      <div class="lsb lsb-absolute lsb-w-full lsb-h-full lsb-max-h-full lsb-overflow-y-scroll lsb-p-2 lsb-border lsb-border-slate-100 lsb-bg-slate-800 lsb-rounded-md">
        <%= for {event_log, index} <- Enum.with_index(@event_logs) do %>
          <.event_log
            id={playground_event_log_id(@story, index)}
            event_log={event_log}
            fa_plan={@fa_plan}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp render_lower_tab_content(assigns = %{lower_tab: :attributes}) do
    ~H"""
    <.form
      :let={f}
      for={%{}}
      as={:playground}
      id={form_id(@story)}
      phx-change="playground-change"
      phx-target={@myself}
      class="lsb-text-gray-600 "
    >
      <div class="lsb lsb-flex lsb-flex-col lsb-mb-2">
        <div class="lsb lsb-overflow-x-auto md:-lsb-mx-8">
          <div class="lsb lsb-inline-block lsb-min-w-full lsb-py-2 lsb-align-middle md:lsb-px-8">
            <div class="lsb lsb-overflow-hidden lsb-shadow lsb-ring-1 lsb-ring-black lsb-ring-opacity-5 md:lsb-rounded-lg">
              <table class="lsb lsb-min-w-full lsb-divide-y lsb-divide-gray-300">
                <thead class="lsb lsb-bg-gray-50">
                  <tr>
                    <%= for {header, th_style, span_style} <- [{"Attribute", "lsb-pl-3 md:lsb-pl-9", "lsb-w-8 md:lsb-w-auto"}, {"Type", "", ""}, {"Documentation", "", ""}, {"Default", "lsb-hidden md:lsb-table-cell", ""}, {"Value", "", ""}] do %>
                      <th
                        scope="col"
                        class={"lsb #{th_style} lsb-py-3.5 lsb-text-left lsb-text-xs md:lsb-text-sm lsb-font-semibold lsb-text-gray-900"}
                      >
                        <span class={"lsb #{span_style} lsb-truncate lsb-inline-block"}>
                          <%= header %>
                        </span>
                      </th>
                    <% end %>
                  </tr>
                </thead>
                <tbody class="lsb lsb-divide-y lsb-divide-gray-200 lsb-bg-white">
                  <%= if Enum.empty?(@story.merged_attributes()) do %>
                    <tr>
                      <td
                        colspan="5"
                        class="lsb md:lsb-px-3 md:lsb-px-6 lsb-py-4 lsb-text-md md:lsb-text-lg lsb-font-medium lsb-text-gray-500 sm:lsb-pl-6 lsb-pt-2 md:lsb-pb-6 md:lsb-pt-4 md:lsb-pb-12 lsb-text-center"
                      >
                        <.fa_icon
                          style={:duotone}
                          name="circle-question"
                          class="fa-xl lsb-text-indigo-400 lsb-py-4 md:lsb-py-6"
                          plan={@fa_plan}
                        />
                        <p>In order to use playground, you must define your component attributes.</p>
                      </td>
                    </tr>
                  <% else %>
                    <%= for attr <- @story.merged_attributes(), !is_nil(@variation)  do %>
                      <tr>
                        <td class="lsb lsb-whitespace-nowrap md:lsb-pr-3 md:lsb-pr-6 lsb-pl-3 md:lsb-pl-9 lsb-py-4 lsb-text-xs md:lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                          <%= if attr.required do %>
                            <.required_badge fa_plan={@fa_plan} />
                          <% end %>
                          <%= attr.id %>
                          <%= if attr.required do %>
                            <span class="lsb lsb-inline md:lsb-hidden lsb-text-indigo-600 lsb-text-sm lsb-font-bold -lsb-ml-0.5">
                              *
                            </span>
                          <% end %>
                        </td>
                        <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-xs md:lsb-text-sm lsb-text-gray-500">
                          <.type_badge type={attr.type} />
                        </td>
                        <td class="lsb lsb-whitespace-pre-line lsb-py-4 md:lsb-pr-3 lsb-text-xs md:lsb-text-sm lsb-text-gray-500 lsb-max-w-[16rem]">
                          <%= if attr.doc, do: String.trim(attr.doc) %>
                        </td>
                        <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-sm lsb-text-gray-500 lsb-hidden md:lsb-table-cell">
                          <span class="lsb lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs md:lsb-text-sm">
                            <%= unless is_nil(attr.default), do: inspect(attr.default) %>
                          </span>
                        </td>
                        <td class="lsb lsb-whitespace-nowrap lsb-pr-3 lsb-lsb-py-4 lsb-text-sm lsb-font-medium">
                          <.maybe_locked_attr_input
                            form={f}
                            attr_id={attr.id}
                            type={attr.type}
                            fields={@fields}
                            values={attr.values}
                            myself={@myself}
                            template_attributes={Map.get(@template_attributes, @variation_id, %{})}
                          />
                        </td>
                      </tr>
                    <% end %>
                    <%= for slot <- @story.merged_slots() do %>
                      <tr>
                        <td class="lsb lsb-whitespace-nowrap md:lsb-pr-3 md:lsb-pr-6 lsb-pl-3 md:lsb-pl-9 lsb-py-4 lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                          <%= if slot.required do %>
                            <.required_badge fa_plan={@fa_plan} />
                          <% end %>
                          <%= slot.id %>
                          <%= if slot.required do %>
                            <span class="lsb lsb-inline md:lsb-hidden lsb-text-indigo-600 lsb-text-sm lsb-font-bold -lsb-ml-0.5">
                              *
                            </span>
                          <% end %>
                        </td>
                        <td class="lsb lsb-whitespace-nowrap lsb-py-4 md:lsb-pr-3 lsb-text-xs md:lsb-text-sm  lsb-text-gray-500">
                          <.type_badge type={:slot} />
                        </td>
                        <td
                          colspan="3"
                          class="lsb lsb-whitespace-pre-line lsb-py-4 md:lsb-pr-3 lsb-text-xs md:lsb-text-sm  lsb-text-gray-500"
                        >
                          <%= if slot.doc, do: String.trim(slot.doc) %>
                        </td>
                      </tr>
                      <%= if slot?(assigns, slot) do %>
                        <tr class="lsb !lsb-border-t-0">
                          <td
                            colspan="5"
                            class="lsb lsb-whitespace-nowrap lsb-pl-3 md:lsb-pl-9 lsb-pr-3 lsb-pb-3 lsb-text-xs md:lsb-text-sm lsb-font-medium lsb-text-gray-900"
                          >
                            <pre class="lsb lsb-text-gray-600 lsb-p-2 lsb-border lsb-border-slate-100 lsb-rounded-md lsb-bg-slate-100 lsb-overflow-x-scroll lsb-whitespace-pre-wrap lsb-break-normal lsb-flex-1"><%= do_render_slot(assigns, slot) %></pre>
                          </td>
                        </tr>
                      <% end %>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </.form>
    <%= unless Enum.empty?(@story.merged_attributes()) do %>
      <.form
        :let={f}
        for={%{}}
        as={:variation}
        id="variation-selection-form"
        class="lsb lsb-flex lsb-flex-col md:lsb-flex-row lsb-space-y-1 md:lsb-space-x-2 lsb-justify-end lsb-w-full lsb-mb-6"
      >
        <%= label(f, :variation_id, "Open a variation",
          class: "lsb lsb-text-gray-400 lsb-text-xs md:lsb-text-sm lsb-self-end md:lsb-self-center"
        ) %>
        <%= select(f, :variation_id, variation_options(@story),
          "phx-change": "set-variation",
          "phx-target": @myself,
          class:
            "lsb lsb-form-select lsb-text-gray-600 lsb-pr-10 lsb-py-1 lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-600 focus:lsb-border-indigo-600 lsb-text-xs md:lsb-text-sm lsb-rounded-md",
          value: @variation_id
        ) %>
      </.form>
    <% end %>
    """
  end

  defp event_log(assigns) do
    ~H"""
    <code class="lsb lsb-text-sm" id={@id}>
      <div
        class="lsb-flex lsb-items-center lsb-group lsb-cursor-pointer"
        phx-click={toggle_event_details(@id)}
      >
        <span class="lsb-uncollapse lsb-mr-1 lsb-text-gray-400 group-hover:lsb-font-bold">
          <.fa_icon style={:thin} name="caret-right" class="fa-fw" plan={@fa_plan} />
        </span>

        <span class="lsb-collapse lsb-mr-1 lsb-hidden lsb-text-gray-400 group-hover:lsb-font-bold">
          <.fa_icon style={:thin} name="caret-down" class="fa-fw" plan={@fa_plan} />
        </span>

        <div>
          <span class="lsb-text-gray-400 group-hover:lsb-font-bold">
            <%= @event_log.time |> Time.truncate(:millisecond) |> Time.to_iso8601() %>
          </span>
          <span class="lsb-text-indigo-500 group-hover:lsb-font-bold"><%= @event_log.type %></span>
          <span class="lsb-text-orange-500 group-hover:lsb-font-bold">
            event:
            <span class="lsb-text-gray-400 group-hover:lsb-font-bold"><%= @event_log.event %></span>
          </span>
        </div>
      </div>

      <div class="lsb-details lsb-hidden lsb-pl-4">
        <%= for {key, value} <- Map.from_struct(@event_log) do %>
          <div>
            <span class="lsb-text-indigo-500"><%= key %>:</span>
            <span class="lsb-text-gray-400"><%= inspect(value) %></span>
          </div>
        <% end %>
      </div>
    </code>
    """
  end

  defp toggle_event_details(id) do
    %JS{}
    |> JS.toggle(to: "##{id} .lsb-collapse")
    |> JS.toggle(to: "##{id} .lsb-uncollapse")
    |> JS.toggle(to: "##{id} .lsb-details")
  end

  defp required_badge(assigns) do
    ~H"""
    <span class="lsb lsb-hidden md:lsb-inline lsb-group lsb-relative -lsb-ml-[1.85em] lsb-pr-2">
      <.fa_icon
        style={:duotone}
        name="circle-dot"
        class="lsb-text-indigo-400 hover:lsb-text-indigo-600 lsb-cursor-pointer"
        plan={@fa_plan}
      />
      <span class="lsb lsb-hidden lsb-absolute lsb-top-6 group-hover:lsb-block lsb-z-50 lsb-mx-auto lsb-text-xs lsb-text-indigo-800 lsb-bg-indigo-100 lsb-rounded lsb-px-2 lsb-py-1">
        Required
      </span>
    </span>
    """
  end

  def slot?(assigns, _slot = %{id: slot_id}) do
    case Map.get(assigns.slots, slot_id) do
      nil -> false
      "" -> false
      _ -> true
    end
  end

  def do_render_slot(assigns, _slot = %{id: slot_id}) do
    case Map.get(assigns.slots, slot_id) do
      :locked -> "[Multiple values]"
      slot -> slot
    end
  end

  defp form_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-form"
  end

  defp playground_preview_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  defp playground_event_logs_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-event-logs"
  end

  defp playground_event_log_id(story, index) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-event-log-#{index}"
  end

  defp variation_options(story) do
    for variation <- story.variations() do
      label =
        if variation.description,
          do: variation.description,
          else: variation.id |> to_string() |> String.capitalize() |> String.replace("_", " ")

      {label, variation.id}
    end
  end

  defp type_badge(assigns = %{type: :string}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :atom}) do
    ~H"""
    <span class={"lsb-bg-blue-100 lsb-text-blue-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :boolean}) do
    ~H"""
    <span class={"lsb-bg-slate-500 lsb-text-white #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :integer}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :float}) do
    ~H"""
    <span class={"lsb-bg-teal-100 lsb-text-teal-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :map}) do
    ~H"""
    <span class={"lsb-bg-fuchsia-100 lsb-text-fuchsia-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :list}) do
    ~H"""
    <span class={"lsb-bg-purple-100 lsb-text-purple-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :slot}) do
    ~H"""
    <span class={"lsb-bg-rose-100 lsb-text-rose-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: _type}) do
    ~H"""
    <span class={"lsb-bg-amber-100 lsb-text-amber-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge_class do
    "lsb lsb-rounded lsb-px-1 md:lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-[0.5em] md:lsb-text-xs"
  end

  defp type_label({:struct, type}) do
    type = type |> inspect() |> String.split(".") |> Enum.at(-1)
    "%#{type}{}"
  end

  defp type_label(type) do
    type |> inspect() |> String.split(".") |> Enum.at(-1)
  end

  defp maybe_locked_attr_input(assigns) do
    case Map.get(assigns.template_attributes, assigns.attr_id) do
      nil ->
        case Map.get(assigns.fields, assigns.attr_id) do
          :locked ->
            ~H|<%= text_input(@form, @attr_id,
  value: "[Multiple values]",
  disabled: true,
  class:
    "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-text-xs md:lsb-text-sm lsb-border-gray-300 lsb-rounded-md"
) %>|

          {:eval, value} ->
            value = String.replace(value, ~s|"|, "")
            assigns |> assign(:value, value) |> attr_input()

          value ->
            assigns |> assign(:value, value) |> attr_input()
        end

      value ->
        assigns = assign(assigns, value: value)

        ~H|<%= text_input(@form, @attr_id,
  value: inspect(@value),
  disabled: true,
  class:
    "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-text-xs md:lsb-text-sm lsb-border-gray-300 lsb-rounded-md"
) %>|
    end
  end

  defp attr_input(assigns = %{type: :boolean, value: value}) do
    assigns =
      assign(assigns,
        bg_class: if(value, do: "lsb-bg-indigo-600", else: "lsb-bg-gray-200"),
        translate_class: if(value, do: "lsb-translate-x-5", else: "lsb-translate-x-0")
      )

    ~H"""
    <button
      type="button"
      phx-click={on_toggle_click(@attr_id, @value)}
      class={"lsb #{@bg_class} lsb-relative lsb-inline-flex lsb-flex-shrink-0 lsb-p-0 lsb-h-6 lsb-w-11 lsb-border-2 lsb-border-transparent lsb-rounded-full lsb-cursor-pointer lsb-transition-colors lsb-ease-in-out lsb-duration-200 focus:lsb-outline-none focus:lsb-ring-2 focus:lsb-ring-offset-2 focus:lsb-ring-indigo-500"}
      phx-target={@myself}
      role="switch"
    >
      <%= hidden_input(@form, @attr_id, value: "#{@value}") %>
      <span class={"lsb #{@translate_class} lsb-form-input lsb-p-0 lsb-border-0 lsb-pointer-events-none lsb-inline-block lsb-h-5 lsb-w-5 lsb-rounded-full lsb-bg-white lsb-shadow lsb-transform lsb-ring-0 lsb-transition lsb-ease-in-out lsb-duration-200"}>
      </span>
    </button>
    """
  end

  defp attr_input(assigns = %{type: type, values: nil})
       when type in [:integer, :float] do
    assigns = assign(assigns, step: if(type == :integer, do: 1, else: 0.01))

    ~H"""
    <%= number_input(@form, @attr_id,
      value: @value,
      step: @step,
      class:
        "lsb lsb-form-input lsb-text-xs md:lsb-text-sm lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-border-gray-300 lsb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{type: :integer, values: min..max}) do
    assigns = assigns |> assign(:min, min) |> assign(:max, max)

    ~H"""
    <%= number_input(@form, @attr_id,
      value: @value,
      min: @min,
      max: @max,
      class:
        "lsb lsb-form-input lsb-text-xs md:lsb-text-sm lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-border-gray-300 lsb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{type: :string, values: nil}) do
    ~H"""
    <%= text_input(@form, @attr_id,
      value: @value,
      class:
        "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-text-xs md:lsb-text-sm lsb-border-gray-300 lsb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{type: _type, values: nil, value: value}) do
    value =
      case value do
        nil -> ""
        s when is_binary(s) -> s
        val -> inspect(val)
      end

    assigns = assign(assigns, value: value)

    ~H"""
    <%= text_input(@form, @attr_id,
      value: @value,
      disabled: true,
      class:
        "lsb lsb-form-input lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-text-xs md:lsb-text-sm lsb-border-gray-300 lsb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{values: values}) when not is_nil(values) do
    assigns = assign(assigns, values: [nil | Enum.map(values, &to_string/1)])

    ~H"""
    <%= select(@form, @attr_id, @values,
      value: @value,
      class:
        "lsb lsb-form-select lsb-mt-1 lsb-block lsb-w-full lsb-pl-3 lsb-pr-10 lsb-py-2 lsb-text-xs md:lsb-text-sm  lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 lsb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{values: values}) when not is_nil(values) do
    attr_input(%{assigns | values: values})
  end

  defp on_toggle_click(attr_id, value) do
    JS.push("playground-toggle", value: %{toggled: [attr_id, !value]})
  end

  def handle_event("upper-tab-navigation", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :upper_tab, String.to_atom(tab))}
  end

  def handle_event("lower-tab-navigation", %{"tab" => tab}, socket) do
    tab = String.to_atom(tab)

    {:noreply,
     socket
     |> assign(:lower_tab, tab)
     |> update(:event_logs_unread, fn current ->
       if tab == :events, do: 0, else: current
     end)}
  end

  def handle_event("playground-change", %{"playground" => params}, socket = %{assigns: assigns}) do
    story = assigns.story

    fields =
      for {key, value} <- params,
          key = String.to_atom(key),
          reduce: assigns.fields do
        acc ->
          attr_definition = Enum.find(story.merged_attributes(), &(&1.id == key))

          if (is_nil(value) || value == "") and !attr_definition.required do
            Map.put(acc, key, nil)
          else
            Map.put(acc, key, cast_value(story, key, value))
          end
      end

    variations = update_variations_attributes(assigns.variations, fields)
    send_attributes(assigns.topic, fields)

    {:noreply, assign(socket, variations: variations, fields: fields)}
  end

  def handle_event(
        "playground-toggle",
        %{"toggled" => [key, value]},
        socket = %{assigns: assigns}
      ) do
    fields = Map.put(assigns.fields, String.to_atom(key), value)

    variations = update_variations_attributes(assigns.variations, fields)
    send_attributes(assigns.topic, fields)
    {:noreply, assign(socket, variations: variations, fields: fields)}
  end

  def handle_event(
        "set-variation",
        %{"variation" => %{"variation_id" => variation_id}},
        s = %{assigns: assigns}
      ) do
    case Enum.find(assigns.story.variations(), &(to_string(&1.id) == variation_id)) do
      nil -> nil
      variation -> send_new_variation(assigns.topic, variation)
    end

    {:noreply,
     patch_to(s, assigns.root_path, assigns.story_path, %{
       tab: :playground,
       variation_id: variation_id
     })}
  end

  defp update_variations_attributes(variations, new_attrs) do
    Enum.map(variations, &update_variation_attributes(&1, new_attrs))
  end

  defp update_variation_attributes(variation, new_attrs) do
    new_attrs = Enum.reject(new_attrs, fn {_attr_id, value} -> value == :locked end) |> Map.new()
    attrs = variation.attributes |> Map.merge(new_attrs) |> Map.reject(fn {_, v} -> is_nil(v) end)
    %{variation | attributes: attrs}
  end

  defp send_attributes(topic, attributes) do
    attributes =
      Enum.reject(attributes, fn {_attr_id, value} -> value == :locked end) |> Map.new()

    PubSub.broadcast!(
      PhoenixStorybook.PubSub,
      topic,
      {:new_attributes_input, attributes}
    )
  end

  defp send_new_variation(topic, variation) do
    PubSub.broadcast!(PhoenixStorybook.PubSub, topic, {:set_variation, variation})
  end

  defp cast_value(story, attr_id, value) do
    attr = story.merged_attributes() |> Enum.find(&(&1.id == attr_id))

    case attr.type do
      :atom -> String.to_atom(value)
      :boolean -> String.to_atom(value)
      :integer -> String.to_integer(value)
      :float -> String.to_float(value)
      _ -> value
    end
  rescue
    _ -> value
  end
end
