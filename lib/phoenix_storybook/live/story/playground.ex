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
     |> assign_new_theme(assigns)
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
    assign_new(socket, :variations, fn ->
      for variation <- variations do
        variation_id = {group_id, variation.id}

        variation
        |> Map.take([:attributes, :let, :slots, :template])
        |> Map.put(:id, variation_id)
        |> put_in([:attributes, :theme], socket.assigns[:theme])
      end
    end)
  end

  # new_attributes may be passed by parent (LiveView) send_update.
  # It happens whenever parent is notified some component assign has been
  # updated by the component itself.
  defp assign_new_variations_attributes(socket, assigns) do
    case Map.get(assigns, :new_variations_attributes) do
      nil ->
        socket

      new_attributes ->
        variations =
          for variation <- socket.assigns.variations do
            variation_id = variation.id

            case Map.get(new_attributes, variation_id) do
              nil -> variation
              new_attrs -> update_variation_attributes(variation, new_attrs)
            end
          end

        socket
        |> assign(:variations, variations)
        |> assign(:fields, playground_fields(socket.assigns.story, variations))
    end
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

  defp assign_new_theme(socket, assigns) do
    case Map.get(assigns, :new_theme) do
      nil ->
        socket

      theme ->
        variations =
          for variation <- socket.assigns.variations do
            update_variation_attributes(variation, %{theme: theme})
          end

        fields = Map.put(socket.assigns.fields, :theme, String.to_existing_atom(theme))

        socket
        |> assign(:fields, fields)
        |> assign(:variations, variations)
    end
  end

  defp assign_playground_fields(socket = %{assigns: %{story: story, variations: variations}}) do
    assign_new(socket, :fields, fn -> playground_fields(story, variations) end)
  end

  defp playground_fields(story, variations) do
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
  end

  defp assign_playground_slots(socket = %{assigns: %{story: story, variations: variations}}) do
    assign_new(socket, :slots, fn ->
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
    end)
  end

  defp matching_slot?(:inner_block, slot) do
    not Regex.match?(~r|<:\w+.*|s, slot)
  end

  defp matching_slot?(slot_id, slot) do
    Regex.match?(~r|<:#{slot_id}.*</:#{slot_id}>|s, slot)
  end

  def render(assigns) do
    ~H"""
    <div id="playground" class="psb psb-flex psb-flex-col psb-flex-1">
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
    <div class="psb psb-border-b psb-border-gray-200 dark:psb-border-slate-600 psb-mb-6">
      <nav class="psb -psb-mb-px psb-flex psb-space-x-8">
        <%= for {tab, label, icon} <- @tabs do %>
          <a
            href="#"
            phx-click="upper-tab-navigation"
            phx-value-tab={tab}
            phx-target={@myself}
            class={[
              active_link(@upper_tab, tab),
              "psb psb-whitespace-nowrap psb-py-4 psb-px-1 psb-border-b-2 psb-font-medium psb-text-sm"
            ]}
          >
            <.fa_icon
              style={:duotone}
              name={icon}
              class={"psb-pr-1 #{active_link(@upper_tab, tab)}"}
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
    <div class="psb psb-border-b psb-border-gray-200 dark:psb-border-slate-600 psb-mt-6 md:psb-mt-12 psb-mb-4">
      <nav class="psb -psb-mb-px psb-flex psb-space-x-8">
        <%= for {tab, label, icon} <- [{:attributes, "Attributes", "table"}, {:events, "Event logs", "list-timeline"}] do %>
          <a
            href="#"
            phx-click="lower-tab-navigation"
            phx-value-tab={tab}
            phx-target={@myself}
            class={"psb #{active_link(@lower_tab, tab)} psb-whitespace-nowrap psb-py-4 psb-px-1 psb-border-b-2 psb-font-medium psb-text-sm"}
          >
            <.fa_icon
              style={:duotone}
              name={icon}
              class={"psb-pr-1 #{active_link(@lower_tab, tab)}"}
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

  defp active_link(same_tab, same_tab),
    do: "psb-border-indigo-500 dark:psb-border-sky-400 psb-text-indigo-600 dark:psb-text-sky-400"

  defp active_link(_current_tab, _tab) do
    "psb-border-transparent psb-text-gray-500 dark:psb-text-slate-400 hover:psb-text-gray-700 dark:hover:psb-text-sky-400 hover:psb-border-gray-300 dark:hover:psb-border-sky-400"
  end

  defp event_counter(:events, count) when count > 0, do: "(#{count})"
  defp event_counter(_, _), do: nil

  defp render_upper_tab_content(assigns = %{upper_tab: _tab}) do
    ~H"""
    <div class="psb psb-relative">
      <div class={[
        "psb psb-min-h-32 psb-border psb-border-slate-100 dark:psb-border-slate-600 psb-rounded-md psb-col-span-5 lg:psb-col-span-2 lg:psb-mb-0 psb-flex psb-items-center psb-justify-center psb-bg-white dark:psb-bg-slate-800 psb-shadow-sm",
        if(@upper_tab != :preview, do: "psb-hidden"),
        if(@story.container() != :iframe, do: "psb-px-2")
      ]}>
        <%= if @story.container() == :iframe do %>
          <iframe
            id={playground_preview_id(@story)}
            src={
              path_to_iframe(@socket, @root_path, @story_path,
                variation_id: to_string(@variation_id),
                theme: to_string(@theme),
                color_mode: to_string(@color_mode),
                playground: true,
                topic: @topic
              )
            }
            height="128"
            class="psb-w-full psb-border-0"
            onload="javascript:(function(o){ var height = o.contentWindow.document.body.scrollHeight; if (height > o.style.height) o.style.height=height+'px'; }(this));"
          />
        <% else %>
          <%= live_render(@socket, PlaygroundPreviewLive,
            id: playground_preview_id(@story),
            session: %{
              "story" => @story,
              "variation_id" => to_string(@variation_id),
              "theme" => to_string(@theme),
              "color_mode" => to_string(@color_mode),
              "topic" => "playground-#{inspect(self())}",
              "backend_module" => @backend_module
            },
            container: {:div, style: "height: 100%; width: 100%;"}
          ) %>
        <% end %>
      </div>
      <div
        :if={@upper_tab == :code}
        class="psb psb-relative psb-group psb-border psb-border-slate-100 dark:psb-border-slate-600 psb-rounded-md psb-col-span-5 lg:psb-col-span-2 lg:psb-mb-0 psb-flex psb-items-center psb-px-2 psb-min-h-32 psb-bg-slate-800 psb-shadow-sm"
      >
        <div
          phx-click={JS.dispatch("psb:copy-code")}
          class="psb psb-hidden group-hover:psb-block psb-bg-slate-700 psb-text-slate-500 hover:psb-text-slate-100 psb-z-10 psb-absolute psb-top-2 psb-right-2 psb-px-2 psb-py-1 psb-rounded-md psb-cursor-pointer"
        >
          <.fa_icon name="copy" class="psb-text-inherit" plan={@fa_plan} />
        </div>
        <.playground_code
          story={@story}
          variation={@variation}
          variations={@variations}
          backend_module={@backend_module}
        />
      </div>
      <%= if @playground_error do %>
        <% error_bg = if @upper_tab == :code, do: "psb-bg-slate/20", else: "psb-bg-white/20" %>
        <div class={"psb psb-absolute psb-inset-2 psb-z-10 psb-backdrop-blur-lg psb-text-red-600 #{error_bg} psb-rounded psb-flex psb-flex-col psb-justify-center psb-items-center psb-space-y-2"}>
          <.fa_icon style={:duotone} name="bomb" class="fa-xl psb-text-red-600" plan={@fa_plan} />
          <span class="psb psb-drop-shadow psb-font-medium">Ohoh, I just crashed!</span>
          <button
            phx-click="psb-clear-playground-error"
            class="psb psb-inline-flex psb-items-center psb-px-2 psb-py-1 psb-border psb-border-transparent psb-text-xs psb-font-medium psb-rounded psb-shadow-sm psb-text-white psb-bg-red-600 hover:psb-bg-red-700 focus:psb-outline-none focus:psb-ring-2 focus:psb-ring-offset-2 focus:psb-ring-red-500"
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
      class="psb psb-flex psb-flex-col psb-grow psb-py-2 psb-relative"
    >
      <div class="psb psb-absolute psb-w-full psb-h-full psb-max-h-full psb-overflow-y-scroll psb-p-2 psb-border psb-border-slate-100 dark:psb-border-slate-600 psb-bg-slate-800 psb-rounded-md">
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
      class="psb-text-gray-600 "
    >
      <div class="psb psb-flex psb-flex-col psb-mb-2">
        <div class="psb psb-overflow-x-auto md:-psb-mx-8">
          <div class="psb psb-inline-block psb-min-w-full psb-py-2 psb-align-middle md:psb-px-8">
            <div class="psb psb-overflow-hidden psb-shadow psb-ring-1 psb-ring-black psb-ring-opacity-5 md:psb-rounded-lg dark:psb-border dark:psb-border-slate-600">
              <table class="psb psb-min-w-full psb-divide-y psb-divide-gray-300 dark:psb-divide-slate-600">
                <thead class="psb psb-bg-gray-50 dark:psb-bg-slate-800">
                  <tr>
                    <%= for {header, th_style, span_style} <- [{"Attribute", "psb-pl-3 md:psb-pl-9", "psb-w-8 md:psb-w-auto"}, {"Type", "", ""}, {"Documentation", "", ""}, {"Default", "psb-hidden md:psb-table-cell", ""}, {"Value", "", ""}] do %>
                      <th
                        scope="col"
                        class={"psb #{th_style} psb-py-3.5 psb-text-left psb-text-xs md:psb-text-sm psb-font-semibold psb-text-gray-900 dark:psb-text-slate-300"}
                      >
                        <span class={"psb #{span_style} psb-truncate psb-inline-block"}>
                          <%= header %>
                        </span>
                      </th>
                    <% end %>
                  </tr>
                </thead>
                <tbody class="psb psb-divide-y psb-divide-gray-200 dark:psb-divide-slate-600 psb-bg-white dark:psb-bg-slate-800">
                  <%= if Enum.empty?(@story.merged_attributes()) do %>
                    <tr>
                      <td
                        colspan="5"
                        class="psb md:psb-px-3 md:psb-px-6 psb-py-4 psb-text-md md:psb-text-lg psb-font-medium psb-text-gray-500 sm:psb-pl-6 psb-pt-2 md:psb-pb-6 md:psb-pt-4 md:psb-pb-12 psb-text-center"
                      >
                        <.fa_icon
                          style={:duotone}
                          name="circle-question"
                          class="fa-xl psb-text-indigo-400 dark:psb-text-sky-400 psb-py-4 md:psb-py-6"
                          plan={@fa_plan}
                        />
                        <p>In order to use playground, you must define your component attributes.</p>
                      </td>
                    </tr>
                  <% else %>
                    <%= for attr <- @story.merged_attributes(), !is_nil(@variation)  do %>
                      <% [doc_head | doc_tail] =
                        if(attr.doc, do: String.split(attr.doc, "\n"), else: [nil]) %>
                      <tr>
                        <td class="psb psb-whitespace-nowrap  md:psb-pr-6 psb-pl-3 sm:psb-pl-6 md:psb-pl-9 psb-py-4 psb-text-xs md:psb-text-sm psb-font-medium psb-text-gray-900 dark:psb-text-slate-300">
                          <%= if attr.required do %>
                            <.required_badge fa_plan={@fa_plan} />
                          <% end %>
                          <%= attr.id %>
                          <%= if attr.required do %>
                            <span class="psb psb-inline md:psb-hidden psb-text-indigo-600 dark:psb-text-sky-400 psb-text-sm psb-font-bold -psb-ml-0.5">
                              *
                            </span>
                          <% end %>
                        </td>
                        <td class="psb psb-whitespace-nowrap psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm psb-text-gray-500">
                          <.type_badge type={attr.type} />
                        </td>
                        <td class="psb psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm psb-text-gray-500 dark:psb-text-slate-300 psb-max-w-[16rem]">
                          <div :if={doc_head}>
                            <span>
                              <%= doc_head |> Earmark.as_html() |> elem(1) |> raw() %>
                            </span>
                            <a
                              :if={Enum.any?(doc_tail)}
                              phx-click={
                                JS.show(to: "#attr-#{attr.id}-doc-next")
                                |> JS.hide()
                                |> JS.show(to: "#attr-#{attr.id}-read-less", display: "inline-block")
                              }
                              id={"attr-#{attr.id}-read-more"}
                              class={[
                                "psb psb-py-2 psb-inline-block psb-text-slate-400 hover:psb-text-indigo-700",
                                "dark:hover:psb-text-sky-400 psb-cursor-pointer psb-h-4"
                              ]}
                            >
                              <.fa_icon
                                name="caret-right"
                                style={:thin}
                                plan={@fa_plan}
                                class="psb-mr-1 psb-h-2"
                              /> Read more
                            </a>
                            <a
                              :if={Enum.any?(doc_tail)}
                              phx-click={
                                JS.hide(to: "#attr-#{attr.id}-doc-next")
                                |> JS.hide()
                                |> JS.show(to: "#attr-#{attr.id}-read-more", display: "inline-block")
                              }
                              id={"attr-#{attr.id}-read-less"}
                              class={[
                                "psb psb-py-2 psb-pb-4 psb-hidden psb-text-slate-400",
                                "hover:psb-text-indigo-700 dark:hover:psb-text-sky-400 psb-cursor-pointer psb-h-4"
                              ]}
                            >
                              <.fa_icon
                                name="caret-down"
                                style={:thin}
                                plan={@fa_plan}
                                class="psb-mr-1 psb-h-2"
                              /> Read less
                            </a>
                          </div>
                        </td>
                        <td class="psb psb-whitespace-nowrap psb-py-4 md:psb-pr-3 psb-text-sm psb-text-gray-500 dark:psb-text-slate-300 psb-hidden md:psb-table-cell">
                          <span class="psb psb-rounded psb-px-2 psb-py-1 psb-font-mono psb-text-xs md:psb-text-sm">
                            <%= unless is_nil(attr.default), do: inspect(attr.default) %>
                          </span>
                        </td>
                        <td class="psb psb-whitespace-nowrap psb-pr-3 psb-psb-py-4 psb-text-sm psb-font-medium">
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
                      <tr
                        :if={Enum.any?(doc_tail)}
                        id={"attr-#{attr.id}-doc-next"}
                        class="psb-hidden psb-relative"
                      >
                        <td
                          colspan="5"
                          class="psb psb-doc psb-text-sm psb-text-gray-500 dark:psb-text-slate-400 psb-bg-slate-50 dark:psb-bg-slate-800 psb-px-3 md:psb-px-8 psb-py-4"
                        >
                          <.fa_icon
                            style={:regular}
                            name="xmark"
                            phx-click={
                              JS.hide(to: "#attr-#{attr.id}-doc-next")
                              |> JS.hide(to: "#attr-#{attr.id}-read-less")
                              |> JS.show(to: "#attr-#{attr.id}-read-more", display: "inline-block")
                            }
                            plan={@fa_plan}
                            class={[
                              "psb-absolute psb-right-2 psb-top-2 ",
                              "hover:psb-text-indigo-600 dark:hover:psb-text-sky-400 psb-cursor-pointer"
                            ]}
                          />
                          <%= doc_tail |> Enum.join("\n") |> Earmark.as_html() |> elem(1) |> raw() %>
                        </td>
                      </tr>
                    <% end %>
                    <%= for slot <- @story.merged_slots() do %>
                      <tr>
                        <td class="psb psb-whitespace-nowrap md:psb-pr-6 sm:psb-pl-6 psb-pl-3 md:psb-pl-9 psb-py-4 psb-text-sm psb-font-medium psb-text-gray-900 dark:psb-text-slate-300">
                          <.required_badge :if={slot.required} fa_plan={@fa_plan} />
                          <%= slot.id %>
                          <span
                            :if={slot.required}
                            class="psb psb-inline md:psb-hidden psb-text-indigo-600 dark:psb-text-sky-400 psb-text-sm psb-font-bold -psb-ml-0.5"
                          >
                            *
                          </span>
                        </td>
                        <td class="psb psb-whitespace-nowrap psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm  psb-text-gray-500">
                          <.type_badge type={:slot} />
                        </td>
                        <td
                          colspan="3"
                          class="psb psb-doc psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm psb-text-gray-500 dark:psb-text-slate-300"
                        >
                          <div :if={slot.doc}>
                            <%= slot.doc |> Earmark.as_html() |> elem(1) |> raw() %>
                          </div>
                        </td>
                      </tr>
                      <tr :if={Enum.any?(slot.attrs)}>
                        <td
                          colspan="5"
                          class="psb psb-whitespace-nowrap md:psb-pr-6 sm:psb-pl-6 psb-pl-3 md:psb-pl-10 psb-py-4 psb-text-sm psb-font-medium psb-text-gray-900 dark:psb-text-slate-300"
                        >
                          <a
                            id={"slot-#{slot.id}-attrs-show"}
                            phx-click={
                              JS.show(to: "#slot-#{slot.id}-attrs")
                              |> JS.hide()
                              |> JS.show(to: "#slot-#{slot.id}-attrs-hide")
                            }
                            class="psb psb-text-slate-400 hover:psb-text-indigo-700 dark:hover:psb-text-sky-400 psb-cursor-pointer"
                          >
                            <.fa_icon
                              name="caret-right"
                              style={:thin}
                              plan={@fa_plan}
                              class="psb-pr-2"
                            /> Show slot attributes
                          </a>
                          <a
                            id={"slot-#{slot.id}-attrs-hide"}
                            phx-click={
                              JS.hide(to: "#slot-#{slot.id}-attrs")
                              |> JS.hide()
                              |> JS.show(to: "#slot-#{slot.id}-attrs-show")
                            }
                            class="psb psb-text-slate-400 hover:psb-text-indigo-700 dark:hover:psb-text-sky-400 psb-cursor-pointer psb-hidden"
                          >
                            <.fa_icon
                              name="caret-down"
                              style={:thin}
                              plan={@fa_plan}
                              class="psb-pr-2"
                            /> Hide slot attributes
                          </a>
                        </td>
                      </tr>
                      <tr
                        :for={attr <- slot.attrs}
                        :if={Enum.any?(slot.attrs)}
                        id={"slot-#{slot.id}-attrs"}
                        class="psb-hidden psb-bg-slate-50 dark:psb-bg-slate-800"
                      >
                        <td class="psb psb-whitespace-nowrap psb-pl-3 sm:psb-pl-6 md:psb-pl-20 psb-py-4 psb-text-sm psb-font-medium psb-text-gray-900 dark:psb-text-slate-300">
                          <.required_badge :if={attr.required} fa_plan={@fa_plan} /> {attr.id}
                          <span
                            :if={attr.required}
                            class="psb psb-inline md:psb-hidden psb-text-indigo-600 dark:psb-text-sky-400 psb-text-sm psb-font-bold -psb-ml-0.5"
                          >
                            *
                          </span>
                        </td>
                        <td class="psb psb-whitespace-nowrap psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm  psb-text-gray-500">
                          <.type_badge type={attr.type} />
                        </td>
                        <td
                          colspan="3"
                          class="psb psb-doc psb-py-4 md:psb-pr-3 psb-text-xs md:psb-text-sm psb-text-gray-500 dark:psb-text-slate-300"
                        >
                          <div :if={attr.doc()}>
                            <%= attr.doc() |> Earmark.as_html() |> elem(1) |> raw() %>
                          </div>
                        </td>
                      </tr>
                      <tr :if={slot?(assigns, slot)} class="psb psb-bg-slate-50 dark:psb-bg-slate-800">
                        <td
                          colspan="5"
                          class="psb psb-whitespace-nowrap psb-pl-3 md:psb-pl-9 psb-pr-3 psb-py-3 psb-text-xs md:psb-text-sm psb-font-medium psb-text-gray-900"
                        >
                          <pre class="psb psb-text-slate-600 dark:psb-text-slate-300 psb-p-2 psb-border psb-border-slate-100 dark:psb-border-slate-600 psb-rounded-md psb-bg-slate-100 dark:psb-bg-slate-900 psb-whitespace-pre-wrap psb-break-normal psb-flex-1"><%= do_render_slot(assigns, slot) %></pre>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </.form>
    <.form
      :let={f}
      :if={Enum.any?(@story.merged_attributes())}
      for={%{}}
      as={:variation}
      id="variation-selection-form"
      class="psb psb-flex psb-flex-col md:psb-flex-row psb-space-y-1 md:psb-space-x-2 psb-justify-end psb-w-full psb-mb-6"
    >
      <%= label(f, :variation_id, "Open a variation",
        class:
          "psb psb-text-gray-400 dark:psb-text-slate-300 psb-text-xs md:psb-text-sm psb-self-end md:psb-self-center"
      ) %>
      <%= select(f, :variation_id, variation_options(@story),
        "phx-change": "set-variation",
        "phx-target": @myself,
        class:
          "psb psb-form-select dark:psb-bg-slate-800 psb-text-gray-600 dark:psb-text-slate-300 psb-pr-10 psb-py-1 psb-border-gray-300 dark:psb-border-slate-600 focus:psb-outline-none focus:psb-ring-indigo-600 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-600 dark:focus:psb-border-sky-400 psb-text-xs md:psb-text-sm psb-rounded-md",
        value: @variation_id
      ) %>
    </.form>
    """
  end

  defp event_log(assigns) do
    ~H"""
    <code class="psb psb-text-sm" id={@id}>
      <div
        class="psb-flex psb-items-center psb-group psb-cursor-pointer"
        phx-click={toggle_event_details(@id)}
      >
        <span class="psb-uncollapse psb-mr-1 psb-text-gray-400 group-hover:psb-font-bold">
          <.fa_icon style={:thin} name="caret-right" class="fa-fw" plan={@fa_plan} />
        </span>

        <span class="psb-collapse psb-mr-1 psb-hidden psb-text-gray-400 group-hover:psb-font-bold">
          <.fa_icon style={:thin} name="caret-down" class="fa-fw" plan={@fa_plan} />
        </span>

        <div>
          <span class="psb-text-gray-400 group-hover:psb-font-bold">
            <%= @event_log.time |> Time.truncate(:millisecond) |> Time.to_iso8601() %>
          </span>
          <span class="psb-text-indigo-500 group-hover:psb-font-bold"><%= @event_log.type %></span>
          <span class="psb-text-orange-500 group-hover:psb-font-bold">
            event:
            <span class="psb-text-gray-400 group-hover:psb-font-bold"><%= @event_log.event %></span>
          </span>
        </div>
      </div>

      <div class="psb-details psb-hidden psb-pl-4">
        <%= for {key, value} <- Map.from_struct(@event_log) do %>
          <div>
            <span class="psb-text-indigo-500"><%= key %>:</span>
            <span class="psb-text-gray-400"><%= inspect(value) %></span>
          </div>
        <% end %>
      </div>
    </code>
    """
  end

  defp toggle_event_details(id) do
    %JS{}
    |> JS.toggle(to: "##{id} .psb-collapse")
    |> JS.toggle(to: "##{id} .psb-uncollapse")
    |> JS.toggle(to: "##{id} .psb-details")
  end

  defp required_badge(assigns) do
    ~H"""
    <span class="psb psb-hidden md:psb-inline psb-group psb-relative -psb-ml-[1.85em] psb-pr-2">
      <.fa_icon
        style={:duotone}
        name="circle-dot"
        class="psb-text-indigo-400 dark:psb-text-sky-400 hover:psb-text-indigo-600 dark:hover:psb-text-sky-600 psb-cursor-pointer"
        plan={@fa_plan}
      />
      <span class="psb psb-hidden psb-absolute psb-top-6 group-hover:psb-block psb-z-50 psb-mx-auto psb-text-xs psb-text-indigo-800 dark:psb-text-sky-400 psb-bg-indigo-100 dark:psb-bg-slate-800 psb-rounded psb-px-2 psb-py-1">
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
    <span class={"psb-bg-slate-100 psb-text-slate-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :atom}) do
    ~H"""
    <span class={"psb-bg-blue-100 psb-text-blue-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :boolean}) do
    ~H"""
    <span class={"psb-bg-slate-500 psb-text-white #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :integer}) do
    ~H"""
    <span class={"psb-bg-green-100 psb-text-green-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :float}) do
    ~H"""
    <span class={"psb-bg-teal-100 psb-text-teal-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :map}) do
    ~H"""
    <span class={"psb-bg-fuchsia-100 psb-text-fuchsia-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :list}) do
    ~H"""
    <span class={"psb-bg-purple-100 psb-text-purple-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: :slot}) do
    ~H"""
    <span class={"psb-bg-rose-100 psb-text-rose-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge(assigns = %{type: _type}) do
    ~H"""
    <span class={"psb-bg-amber-100 psb-text-amber-800 #{type_badge_class()}"}>
      <%= type_label(@type) %>
    </span>
    """
  end

  defp type_badge_class do
    "psb psb-rounded psb-px-1 md:psb-px-2 psb-py-1 psb-font-mono psb-text-[0.5em] md:psb-text-xs"
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
    "psb psb-form-input psb-cursor-not-allowed psb-block psb-w-full psb-shadow-sm focus:psb-ring-indigo-500 focus:psb-border-indigo-500 psb-text-xs md:psb-text-sm psb-bg-gray-100 dark:psb-bg-slate-800 psb-border-gray-300 dark:psb-border-slate-600 psb-rounded-md"
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
    "psb psb-form-input psb-cursor-not-allowed psb-block psb-w-full psb-shadow-sm focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-border-sky-400 psb-text-xs md:psb-text-sm psb-bg-gray-100 dark:psb-bg-slate-800 psb-border-gray-300 dark:psb-border-slate-600  psb-rounded-md"
) %>|
    end
  end

  defp attr_input(assigns = %{type: :boolean, value: value}) do
    assigns =
      assign(assigns,
        bg_class:
          if(value,
            do: "psb-bg-indigo-600 dark:psb-bg-sky-400",
            else: "psb-bg-gray-200 dark:psb-bg-slate-700"
          ),
        translate_class: if(value, do: "psb-translate-x-5", else: "psb-translate-x-0")
      )

    ~H"""
    <button
      type="button"
      phx-click={on_toggle_click(@attr_id, @value)}
      class={"psb #{@bg_class} psb-relative psb-inline-flex psb-flex-shrink-0 psb-p-0 psb-h-6 psb-w-11 psb-border-2 psb-border-transparent psb-rounded-full psb-cursor-pointer psb-transition-colors psb-ease-in-out psb-duration-200 focus:psb-outline-none focus:psb-ring-2 focus:psb-ring-offset-2 focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400"}
      phx-target={@myself}
      role="switch"
    >
      <%= hidden_input(@form, @attr_id, value: "#{@value}") %>
      <span class={"psb #{@translate_class} psb-form-input psb-p-0 psb-border-0 psb-pointer-events-none psb-inline-block psb-h-5 psb-w-5 psb-rounded-full psb-bg-white psb-shadow psb-transform psb-ring-0 psb-transition psb-ease-in-out psb-duration-200"}>
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
        "psb psb-form-input psb-text-xs md:psb-text-sm psb-block psb-w-full dark:psb-text-slate-300 dark:psb-bg-slate-700 psb-shadow-sm focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-ring-sky-400 psb-border-gray-300 dark:psb-border-slate-600 psb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{type: :integer, values: min..max//_}) do
    assigns = assigns |> assign(:min, min) |> assign(:max, max)

    ~H"""
    <%= number_input(@form, @attr_id,
      value: @value,
      min: @min,
      max: @max,
      class:
        "psb psb-form-input psb-text-xs md:psb-text-sm psb-block psb-w-full dark:psb-text-slate-300 dark:psb-bg-slate-700 psb-shadow-sm focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-ring-sky-400 psb-border-gray-300 dark:psb-border-slate-600 psb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{type: :string, values: nil}) do
    ~H"""
    <%= text_input(@form, @attr_id,
      value: @value,
      class:
        "psb psb-form-input psb-block psb-w-full dark:psb-text-slate-300 dark:psb-bg-slate-700 psb-shadow-sm focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-ring-sky-400 psb-border-gray-300 dark:psb-border-slate-600 psb-text-xs md:psb-text-sm psb-rounded-md"
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
        "psb psb-cursor-not-allowed psb-bg-gray-100 psb-form-input psb-block psb-w-full dark:psb-text-slate-700 dark:psb-bg-slate-800 psb-shadow-sm focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-ring-sky-400 psb-border-gray-300 dark:psb-border-slate-600 psb-text-xs md:psb-text-sm psb-rounded-md"
    ) %>
    """
  end

  defp attr_input(assigns = %{values: values}) when not is_nil(values) do
    assigns = assign(assigns, values: [nil | Enum.map(values, &to_string/1)])

    ~H"""
    <%= select(@form, @attr_id, @values,
      value: @value,
      class:
        "psb psb-form-select psb-mt-1 psb-block psb-w-full dark:psb-text-slate-300 dark:psb-bg-slate-700 psb-pl-3 psb-pr-10 psb-py-2 psb-text-xs md:psb-text-sm focus:psb-outline-none focus:psb-ring-indigo-500 dark:focus:psb-ring-sky-400 focus:psb-border-indigo-500 dark:focus:psb-ring-sky-400 psb-border-gray-300 dark:psb-border-slate-600 psb-rounded-md"
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
