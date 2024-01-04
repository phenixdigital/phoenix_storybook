defmodule PhoenixStorybook.StoryLive do
  use PhoenixStorybook.Web, :live_view

  alias Phoenix.HTML.Safe
  alias Phoenix.{LiveView.JS, PubSub}

  alias PhoenixStorybook.Events.EventLog
  alias PhoenixStorybook.ExtraAssignsHelpers
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.Rendering.{CodeRenderer, ComponentRenderer, RenderingContext}
  alias PhoenixStorybook.Story.{Playground, PlaygroundPreviewLive}
  alias PhoenixStorybook.{StoryNotFound, StoryTabNotFound}
  alias PhoenixStorybook.ThemeHelpers

  import PhoenixStorybook.NavigationHelpers

  def mount(_params, _session, socket) do
    connect_params = get_connect_params(socket)["extra"]
    playground_topic = "playground-#{inspect(self())}"
    event_logs_topic = "event_logs:#{inspect(self())}"

    if connected?(socket) do
      PubSub.subscribe(PhoenixStorybook.PubSub, playground_topic)
      PubSub.subscribe(PhoenixStorybook.PubSub, event_logs_topic)
    end

    backend_module = socket.assigns.backend_module

    {:ok,
     assign(socket,
       playground_error: nil,
       playground_preview_pid: nil,
       playground_topic: playground_topic,
       fa_plan: backend_module.config(:font_awesome_plan, :free),
       connect_params: connect_params
     )}
  end

  def handle_params(params, _uri, socket) when params == %{} do
    case first_story_path(socket) do
      nil -> {:noreply, socket}
      path -> {:noreply, patch_to(socket, socket.assigns.root_path, path)}
    end
  end

  def handle_params(params = %{"story" => story_path}, _uri, socket = %{assigns: assigns}) do
    case load_story(socket, story_path) do
      {:ok, story} ->
        variation = current_variation(story.storybook_type(), story, params)
        story_entry = story_entry(socket, story_path)
        theme = current_theme(params, socket)

        ThemeHelpers.call_theme_function(assigns.backend_module, theme)

        {:noreply,
         assign(socket,
           story_load_error: nil,
           story_load_exception: nil,
           story: story,
           story_entry: story_entry,
           story_path: assigns.backend_module.storybook_path(story),
           variation: variation,
           variation_id: if(variation, do: variation.id, else: nil),
           page_title: story_entry.name,
           tab: current_tab(params, story),
           theme: theme,
           variation_extra_assigns:
             ExtraAssignsHelpers.init_variation_extra_assigns(story.storybook_type(), story),
           playground_error: nil
         )
         |> close_sidebar()}

      {:error, :not_found} ->
        raise StoryNotFound, "unknown story #{inspect(story_path)}"

      {:error, error, exception} ->
        {:noreply,
         assign(socket,
           story_load_error: error,
           story_load_exception: exception,
           story_path: Path.join(["/" | story_path])
         )
         |> close_sidebar()}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp first_story_path(socket) do
    socket.assigns.backend_module.leaves() |> Enum.at(0, %{}) |> Map.get(:path)
  end

  defp load_story(socket, story_param) do
    story_path = Path.join(story_param)
    socket.assigns.backend_module.load_story(story_path)
  end

  defp story_entry(socket, story_param) do
    story_path = Path.join(["/" | story_param])
    socket.assigns.backend_module.find_entry_by_path(story_path)
  end

  defp current_variation(type, story, %{"variation_id" => variation_id})
       when type in [:component, :live_component] do
    Enum.find(story.variations(), &(to_string(&1.id) == variation_id))
  end

  defp current_variation(type, story, _) when type in [:component, :live_component] do
    case story.variations() do
      [variation | _] -> variation
      _ -> nil
    end
  end

  defp current_variation(_type, _story, _params), do: nil

  defp current_tab(params, story) do
    case Map.get(params, "tab") do
      nil -> default_tab(story)
      tab -> String.to_atom(tab)
    end
  end

  defp default_tab(story_module) when is_atom(story_module) do
    default_tab(story_module.storybook_type(), story_module)
  end

  defp default_tab(:component, _story_module), do: :variations
  defp default_tab(:live_component, _story_module), do: :variations
  defp default_tab(:example, _story_module), do: :example

  defp default_tab(:page, story_module) do
    case story_module.navigation() do
      [] -> nil
      [{tab, _} | _] -> tab
      [{tab, _, _} | _] -> tab
    end
  end

  defp current_theme(params, socket) do
    case Map.get(params, "theme") do
      nil -> default_theme(socket)
      theme -> String.to_atom(theme)
    end
  end

  defp default_theme(socket) do
    case socket.assigns.backend_module.config(:themes) do
      nil -> nil
      [{theme, _} | _] -> theme
    end
  end

  defp close_sidebar(socket), do: push_event(socket, "psb:close-sidebar", %{"id" => "#sidebar"})

  def render(assigns = %{story_load_error: error})
      when not is_nil(error) do
    ~H"""
    <div class="psb psb-my-6 md:psb-my-12 psb-space-y-4 md:psb-space-y-8 psb-flex psb-flex-col">
      <h1 class="psb psb-font-medium psb-text-red-500 psb-text-lg md:psb-text-xl lg:psb-text-2xl psb-align-middle">
        <.fa_icon style={:duotone} name="bomb" plan={@fa_plan} />
        <%= @story_load_error %>
      </h1>

      <div class="psb psb-border psb-rounded-md psb-border-slate-100 psb-bg-slate-800 psb-p-4 psb-overflow-x-scroll">
        <pre class="psb psb-text-xs md:psb-text-sm psb-leading-loose psb-text-red-500"><%= @story_load_exception %></pre>
      </div>
    </div>
    """
  end

  def render(assigns = %{story: story}) do
    assigns = assign(assigns, story: story, doc: story.doc())

    ~H"""
    <div
      class="psb psb-space-y-6 psb-pb-12 psb-flex psb-flex-col psb-h-[calc(100vh_-_7rem)] lg:psb-h-[calc(100vh_-_4rem)]"
      id="story-live"
      phx-hook="StoryHook"
    >
      <div class="psb">
        <div class="psb psb-flex psb-my-6 psb-items-center">
          <h2 class="psb psb-flex-1 psb-flex-nowrap psb-whitespace-nowrap psb-text-xl md:psb-text-2xl lg:psb-text-3xl psb-m-0 psb-font-extrabold psb-tracking-tight psb-text-indigo-600">
            <%= if icon = @story_entry.icon do %>
              <.user_icon icon={icon} class="psb-pr-2 psb-text-indigo-600" fa_plan={@fa_plan} />
            <% end %>
            <%= @story_entry.name %>
          </h2>

          <%= @story |> navigation_tabs() |> render_navigation_tabs(assigns) %>
        </div>
        <.print_doc doc={@doc} fa_plan={@fa_plan} />
      </div>

      <%= render_content(@story.storybook_type(), assigns) %>
    </div>
    """
  end

  def render(assigns), do: ~H[]

  defp print_doc(assigns = %{doc: doc}) when is_binary(doc) do
    ~H"<.print_doc doc={[@doc]} />"
  end

  defp print_doc(assigns = %{doc: [_header | _]}) do
    ~H"""
    <div class="psb psb-text-base md:psb-text-lg psb-leading-7 psb-text-slate-700">
      <%= @doc |> Enum.at(0) |> raw() %>
    </div>
    <%= if Enum.count(@doc) > 1 do %>
      <a
        phx-click={JS.show(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-less")}
        id="read-more"
        class="psb psb-py-2 psb-inline-block psb-text-slate-400 hover:psb-text-indigo-700 psb-cursor-pointer"
      >
        <.fa_icon
          name="caret-right"
          style={:thin}
          plan={@fa_plan}
          class="psb-relative psb-top-px psb-mr-1"
        /> Read more
      </a>
      <a
        phx-click={JS.hide(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-more")}
        id="read-less"
        class="psb psb-pt-2 psb-pb-4 psb-hidden psb-inline-block psb-text-slate-400 hover:psb-text-indigo-700 psb-cursor-pointer"
      >
        <.fa_icon name="caret-down" style={:thin} plan={@fa_plan} class="psb-mr-1" /> Read less
      </a>
      <div id="doc-next" class="psb-hidden psb-space-y-4 ">
        <%= for paragraph <- Enum.slice(@doc, 1..-1) do %>
          <div class="psb psb-text-sm md:psb-text-base psb-leading-7 psb-text-slate-700">
            <%= raw(paragraph) %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp print_doc(assigns), do: ~H""

  defp navigation_tabs(story) do
    case story.storybook_type() do
      type when type in [:component, :live_component] ->
        [
          {:variations, "Stories", {:fa, "eye", :regular}},
          {:playground, "Playground", {:fa, "dice", :regular}},
          {:source, "Source", source_icon()}
        ]

      :example ->
        navigation = [
          {:example, "Example", {:fa, "lightbulb", :regular}},
          {:source, Path.basename(story.__file_path__()), source_icon()}
        ]

        source_tabs =
          for source <- story.extra_sources() do
            name = source |> Path.basename()
            {String.to_atom(source), name, source_icon()}
          end

        navigation ++ source_tabs

      :page ->
        story.navigation()
    end
  end

  defp source_icon, do: {:fa, "file-code", :regular}

  defp render_navigation_tabs([], assigns), do: ~H""

  defp render_navigation_tabs(tabs, assigns) do
    assigns = assign(assigns, :tabs, tabs)

    ~H"""
    <div class="psb psb-flex psb-flex-items-center">
      <!-- mobile version of navigation tabs -->
      <.form
        :let={f}
        for={%{}}
        as={:navigation}
        id={"#{Macro.underscore(@story)}-navigation-form"}
        class="psb story-nav-form lg:psb-hidden"
      >
        <%= select(f, :tab, navigation_select_options(@tabs),
          "phx-change": "psb-set-tab",
          class:
            "psb psb-form-select psb-w-full psb-pl-3 psb-pr-10 psb-py-1 psb-text-base psb-border-gray-300 focus:psb-outline-none focus:psb-ring-indigo-600 focus:psb-border-indigo-600 sm:psb-text-sm psb-rounded-md",
          value: @tab
        ) %>
      </.form>
      <!-- :lg+ version of navigation tabs -->
      <nav class="psb story-tabs psb-hidden lg:psb-flex psb-rounded-lg psb-border psb-bg-slate-100 psb-hover:psb-bg-slate-200 psb-h-10 psb-text-sm psb-font-medium">
        <%= for tab <- @tabs do %>
          <% {tab_id, tab_label} = {elem(tab, 0), elem(tab, 1)} %>
          <a
            href="#"
            phx-click="psb-set-tab"
            phx-value-tab={tab_id}
            class={"psb psb-group focus:psb-outline-none psb-flex psb-rounded-md #{active_link(@tab, tab_id)}"}
          >
            <span class={active_span(@tab, tab_id)}>
              <% icon = if tuple_size(tab) == 3, do: elem(tab, 2), else: nil %>
              <%= if icon do %>
                <.user_icon
                  icon={icon}
                  class={"lg:psb-mr-2 group-hover:psb-text-indigo-600 #{active_text(@tab, tab_id)}"}
                  fa_plan={@fa_plan}
                />
              <% end %>
              <span class={"psb psb-whitespace-nowrap group-hover:psb-text-indigo-600 #{active_text(@tab, tab_id)}"}>
                <%= tab_label %>
              </span>
            </span>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp active_link(same, same), do: "psb psb-bg-white psb-opacity-100"

  defp active_link(_tab, _current_tab) do
    "psb psb-ml-0.5 psb-p-1.5 lg:psb-pl-2.5 lg:psb-pr-3.5 psb-items-center psb-text-slate-600"
  end

  defp active_span(same, same) do
    "psb psb-h-full psb-rounded-md psb-flex psb-items-center psb-bg-white psb-shadow-sm \
    psb-ring-opacity-5 psb-text-indigo-600 psb-p-1.5 lg:psb-pl-2.5 lg:psb-pr-3.5"
  end

  defp active_span(_tab, _current_tab), do: ""

  defp active_text(same, same), do: "psb-text-indigo-600"
  defp active_text(_tab, _current_tab), do: "-psb-ml-0.5"

  defp navigation_select_options(tabs) do
    for {tab, label, _icon} <- tabs, do: {label, tab}
  end

  defp render_content(type, assigns = %{tab: :variations})
       when type in [:component, :live_component] do
    assigns =
      assign(assigns,
        sandbox_attributes:
          case assigns.story.container() do
            {:div, opts} -> assigns_to_attributes(opts, [:class])
            {:iframe, opts} -> assigns_to_attributes(opts, [:style])
            _ -> []
          end
      )

    ~H"""
    <div class="psb psb-space-y-12 psb-pb-12" id={"story-variations-#{story_id(@story)}"}>
      <%= for variation = %{id: variation_id, description: description} <- @story.variations(),
              extra_attributes = ExtraAssignsHelpers.variation_extra_attributes(variation, assigns),
              rendering_context = RenderingContext.build(assigns.backend_module, assigns.story, variation, extra_attributes) do %>
        <div
          id={anchor_id(variation)}
          class="psb psb-variation-block psb-gap-x-4 psb-grid psb-grid-cols-5"
        >
          <!-- Variation description -->
          <div class="psb psb-col-span-5 psb-font-medium hover:psb-font-semibold psb-mb-6 psb-border-b psb-border-slate-100 md:psb-text-lg psb-leading-7 psb-text-slate-700 psb-flex psb-justify-between">
            <%= link to: "##{anchor_id(variation)}", class: "psb variation-anchor-link" do %>
              <.fa_icon
                style={:light}
                name="link"
                class="psb-hidden -psb-ml-8 psb-pr-1 psb-text-slate-400"
                plan={@fa_plan}
              />
              <%= if description do %>
                <%= description %>
              <% else %>
                <%= variation_id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            <% end %>
            <.link
              patch={
                path_to(@socket, @root_path, @story_path, %{
                  tab: :playground,
                  variation_id: variation.id,
                  theme: @theme
                })
              }
              class="psb psb-hidden psb-open-playground-link"
            >
              <span class="psb psb-text-base psb-font-light psb-text-gray-500 hover:psb-text-indigo-600 hover:psb-font-medium ">
                Open in playground <.fa_icon style={:regular} name="arrow-right" plan={@fa_plan} />
              </span>
            </.link>
          </div>
          <!-- Variation component preview -->
          <div
            id={"#{anchor_id(variation)}-component"}
            class={[
              "psb psb-border psb-border-slate-100 psb-rounded-md psb-col-span-5  psb-mb-4 lg:psb-mb-0 psb-flex psb-items-center psb-justify-center psb-p-2 psb-bg-white psb-shadow-sm",
              component_layout_class(@story)
            ]}
          >
            <%= case {LayoutView.normalize_story_container(@story.container()), @story.storybook_type()} do %>
              <% {{:iframe, iframe_opts}, :component} -> %>
                <iframe
                  phx-update="ignore"
                  id={iframe_id(@story, variation)}
                  class="psb-w-full psb-border-0"
                  srcdoc={iframe_srcdoc(assigns, rendering_context, iframe_opts)}
                  height="0"
                  onload={iframe_onload_js()}
                  {@sandbox_attributes}
                />
              <% {{:iframe, _iframe_opts}, :live_component} -> %>
                <iframe
                  phx-update="ignore"
                  id={iframe_id(@story, variation)}
                  class="psb-w-full psb-border-0"
                  src={
                    path_to_iframe(@socket, @root_path, @story_path,
                      variation_id: variation.id,
                      theme: @theme
                    )
                  }
                  height="0"
                  onload={iframe_onload_js()}
                  {@sandbox_attributes}
                />
              <% {container_with_opts, _component_kind} -> %>
                <div
                  class={LayoutView.sandbox_class(@socket, container_with_opts, assigns)}
                  {@sandbox_attributes}
                >
                  <%= ComponentRenderer.render(rendering_context) %>
                </div>
            <% end %>
          </div>
          <!-- Variation code -->
          <div
            id={"#{anchor_id(variation)}-code"}
            class={[
              "psb psb-border psb-border-slate-100 psb-bg-slate-800 psb-rounded-md psb-col-span-5 psb-group psb-relative psb-shadow-sm psb-flex psb-flex-col psb-justify-center",
              code_layout_class(@story)
            ]}
          >
            <div
              phx-click={JS.dispatch("psb:copy-code")}
              class="psb psb-hidden group-hover:psb-block psb-bg-slate-700 psb-text-slate-500 hover:psb-text-slate-100 psb-z-10 psb-absolute psb-top-2 psb-right-2 psb-px-2 psb-py-1 psb-rounded-md psb-cursor-pointer"
            >
              <.fa_icon name="copy" class="psb-text-inherit" plan={@fa_plan} />
            </div>
            <%= CodeRenderer.render(rendering_context) %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_content(type, assigns = %{tab: :source})
       when type in [:component, :live_component] do
    ~H"""
    <div class="psb psb-flex-1 psb-flex psb-flex-col psb-overflow-auto psb-max-h-full">
      <%= @story |> CodeRenderer.render_component_source() |> to_raw_html() %>
    </div>
    """
  end

  defp render_content(type, assigns = %{tab: :playground})
       when type in [:component, :live_component] do
    ~H"""
    <.live_component
      module={Playground}
      id="playground"
      story={@story}
      story_path={@story_path}
      backend_module={@backend_module}
      variation={@variation}
      playground_error={@playground_error}
      theme={@theme}
      topic={@playground_topic}
      fa_plan={@fa_plan}
      root_path={@root_path}
    />
    """
  end

  defp render_content(type, _assigns = %{tab: tab})
       when type in [:component, :live_component],
       do: raise(StoryTabNotFound, "unknown story tab #{inspect(tab)}")

  defp render_content(:page, assigns) do
    ~H"""
    <div class={LayoutView.sandbox_class(@socket, {:div, class: "psb psb-pb-12"}, assigns)}>
      <%= @story.render(%{__changed__: %{}, tab: @tab, theme: @theme, connect_params: @connect_params})
      |> to_raw_html() %>
    </div>
    """
  end

  defp render_content(:example, assigns = %{tab: :example}) do
    theme = Map.get(assigns, :theme)

    live_render(assigns.socket, assigns.story,
      id: "example-#{story_id(assigns.story)}-#{theme}",
      session: %{"theme" => theme},
      container:
        {:div,
         class: LayoutView.sandbox_class(assigns.socket, {:div, class: "psb psb-pb-12"}, assigns)}
    )
  end

  defp render_content(:example, assigns = %{tab: :source}) do
    ~H"""
    <div class="psb psb-flex-1 psb-flex psb-flex-col psb-overflow-auto psb-max-h-full">
      <%= @story.__source__()
      |> remove_example_code()
      |> CodeRenderer.render_source()
      |> to_raw_html() %>
    </div>
    """
  end

  defp render_content(:example, assigns = %{story: story, tab: source_path}) do
    case Map.get(story.__extra_sources__(), to_string(source_path)) do
      nil ->
        ~H[]

      source ->
        assigns = assign(assigns, :source, source)

        ~H"""
        <div class="psb psb-flex-1 psb-flex psb-flex-col psb-overflow-auto psb-max-h-full">
          <%= @source |> CodeRenderer.render_source() |> to_raw_html() %>
        </div>
        """
    end
  end

  defp component_layout_class(story) do
    case story.layout() do
      :one_column -> nil
      :two_columns -> "lg:psb-col-span-2"
    end
  end

  defp code_layout_class(story) do
    case story.layout() do
      :one_column -> nil
      :two_columns -> "lg:psb-col-span-3"
    end
  end

  defp iframe_srcdoc(assigns, rendering_context, iframe_opts) do
    assigns =
      assign(assigns,
        conn: assigns.socket,
        rendering_context: rendering_context,
        iframe_opts: iframe_opts
      )

    ~H"""
    <%= Phoenix.View.render_layout LayoutView, "root_iframe.html", assigns do %>
      <div style={@iframe_opts[:style]}>
        <%= ComponentRenderer.render(@rendering_context) %>
      </div>
    <% end %>
    """
    |> Safe.to_iodata()
  end

  defp iframe_onload_js do
    "javascript:(function(o){o.style.height=o.contentWindow.document.body.scrollHeight+'px';}(this));"
  end

  # removing Storybook's specific not useful while reading example's source code.
  defp remove_example_code(code) do
    code
    # removing specifc storybook use
    |> String.replace(~r|use\s+PhoenixStorybook\.Story\s*,\s*:example|, "use Phoenix.LiveView")
    # removing multiline doc and extra_sources definition
    |> String.replace(~r/def\s+(doc|extra_sources)\s*,\s*do:((?!end).)*end\s*/s, "")
    # removing inline doc and extra_sources definition
    |> String.replace(~r/def\s+(doc|extra_sources)\s+do:((?!end|def).)*/s, "")
  end

  defp to_raw_html(heex) do
    heex
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp iframe_id(story, variation) do
    "iframe-#{story_id(story)}-variation-#{variation.id}"
  end

  defp story_id(story_module) do
    story_module |> Macro.underscore() |> String.replace("/", "_")
  end

  defp anchor_id(%{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end

  def handle_event("psb-set-theme", %{"theme" => theme}, socket) do
    PubSub.broadcast!(
      PhoenixStorybook.PubSub,
      socket.assigns.playground_topic,
      {:set_theme, String.to_atom(theme)}
    )

    ThemeHelpers.call_theme_function(socket.assigns.backend_module, theme)

    {:noreply,
     socket
     |> assign(:theme, theme)
     |> patch_to(socket.assigns.root_path, socket.assigns.story_path, %{theme: theme})}
  end

  def handle_event("psb-set-tab", %{"tab" => tab}, socket) do
    {:noreply, patch_to(socket, socket.assigns.root_path, socket.assigns.story_path, %{tab: tab})}
  end

  def handle_event("psb-set-tab", %{"navigation" => %{"tab" => tab}}, socket) do
    {:noreply, patch_to(socket, socket.assigns.root_path, socket.assigns.story_path, %{tab: tab})}
  end

  def handle_event("psb-clear-playground-error", _, socket) do
    {:noreply, assign(socket, :playground_error, nil)}
  end

  def handle_event("psb-assign", assign_params, socket = %{assigns: assigns}) do
    {variation_id, variation_extra_assigns} =
      ExtraAssignsHelpers.handle_set_variation_assign(
        assign_params,
        assigns.variation_extra_assigns,
        assigns.story
      )

    variation_extra_assigns = %{
      assigns.variation_extra_assigns
      | variation_id => variation_extra_assigns
    }

    {:noreply, assign(socket, :variation_extra_assigns, variation_extra_assigns)}
  end

  def handle_event("psb-toggle", assign_params, socket = %{assigns: assigns}) do
    {variation_id, variation_extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_variation_assign(
        assign_params,
        assigns.variation_extra_assigns,
        assigns.story
      )

    variation_extra_assigns = %{
      assigns.variation_extra_assigns
      | variation_id => variation_extra_assigns
    }

    {:noreply, assign(socket, :variation_extra_assigns, variation_extra_assigns)}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def handle_info({:playground_preview_pid, pid}, socket) do
    Process.monitor(pid)

    {:noreply, assign(socket, :playground_preview_pid, pid)}
  end

  def handle_info({:component_iframe_pid, pid}, socket) do
    PubSub.subscribe(PhoenixStorybook.PubSub, "event_logs:#{inspect(pid)}")
    {:noreply, socket}
  end

  def handle_info(event_log = %EventLog{view: PlaygroundPreviewLive}, socket) do
    send_update(Playground, id: "playground", new_event: event_log)
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, {:shutdown, :closed}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, socket)
      when socket.assigns.playground_preview_pid == pid do
    {:noreply, assign(socket, :playground_error, reason)}
  end

  def handle_info({:new_variations_attributes, variations_attributes}, socket) do
    send_update(Playground, id: "playground", new_variations_attributes: variations_attributes)
    {:noreply, socket}
  end

  def handle_info({:new_template_attributes, template_attributes}, socket) do
    send_update(Playground, id: "playground", new_template_attributes: template_attributes)
    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end

defmodule PhoenixStorybook.StoryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhoenixStorybook.StoryTabNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
