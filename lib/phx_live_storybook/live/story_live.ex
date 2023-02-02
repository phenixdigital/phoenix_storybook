defmodule PhxLiveStorybook.StoryLive do
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.HTML.Safe
  alias Phoenix.{LiveView.JS, PubSub}

  alias PhxLiveStorybook.Events.EventLog
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.Rendering.{CodeRenderer, ComponentRenderer, RenderingContext}
  alias PhxLiveStorybook.Story.{Playground, PlaygroundPreviewLive}
  alias PhxLiveStorybook.{StoryNotFound, StoryTabNotFound}
  alias PhxLiveStorybook.ThemeHelpers

  import PhxLiveStorybook.NavigationHelpers

  def mount(_params, _session, socket) do
    connect_params = get_connect_params(socket)["extra"]
    playground_topic = "playground-#{inspect(self())}"
    event_logs_topic = "event_logs:#{inspect(self())}"

    if connected?(socket) do
      PubSub.subscribe(PhxLiveStorybook.PubSub, playground_topic)
      PubSub.subscribe(PhxLiveStorybook.PubSub, event_logs_topic)
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

  defp close_sidebar(socket), do: push_event(socket, "lsb:close-sidebar", %{"id" => "#sidebar"})

  def render(assigns = %{story_load_error: error})
      when not is_nil(error) do
    ~H"""
    <div class="lsb lsb-my-6 md:lsb-my-12 lsb-space-y-4 md:lsb-space-y-8 lsb-flex lsb-flex-col">
      <h1 class="lsb lsb-font-medium lsb-text-red-500 lsb-text-lg md:lsb-text-xl lg:lsb-text-2xl lsb-align-middle">
        <.fa_icon style={:duotone} name="bomb" plan={@fa_plan} />
        <%= @story_load_error %>
      </h1>

      <div class="lsb lsb-border lsb-rounded-md lsb-border-slate-100 lsb-bg-slate-800 lsb-p-4 lsb-overflow-x-scroll">
        <pre class="lsb lsb-text-xs md:lsb-text-sm lsb-leading-loose lsb-text-red-500"><%= @story_load_exception %></pre>
      </div>
    </div>
    """
  end

  def render(assigns = %{story: story}) do
    assigns = assign(assigns, story: story, doc: story.doc())

    ~H"""
    <div
      class="lsb lsb-space-y-6 lsb-pb-12 lsb-flex lsb-flex-col lsb-h-[calc(100vh_-_7rem)] lg:lsb-h-[calc(100vh_-_4rem)]"
      id="story-live"
      phx-hook="StoryHook"
    >
      <div class="lsb">
        <div class="lsb lsb-flex lsb-my-6 lsb-items-center">
          <h2 class="lsb lsb-flex-1 lsb-flex-nowrap lsb-whitespace-nowrap lsb-text-xl md:lsb-text-2xl lg:lsb-text-3xl lsb-m-0 lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
            <%= if icon = @story_entry.icon do %>
              <.user_icon icon={icon} class="lsb-pr-2 lsb-text-indigo-600" fa_plan={@fa_plan} />
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
    <div class="lsb lsb-text-base md:lsb-text-lg lsb-leading-7 lsb-text-slate-700">
      <%= @doc |> Enum.at(0) |> raw() %>
    </div>
    <%= if Enum.count(@doc) > 1 do %>
      <a
        phx-click={JS.show(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-less")}
        id="read-more"
        class="lsb lsb-py-2 lsb-inline-block lsb-text-slate-400 hover:lsb-text-indigo-700 lsb-cursor-pointer"
      >
        <.fa_icon
          name="caret-right"
          style={:thin}
          plan={@fa_plan}
          class="lsb-relative lsb-top-px lsb-mr-1"
        /> Read more
      </a>
      <a
        phx-click={JS.hide(to: "#doc-next") |> JS.hide() |> JS.show(to: "#read-more")}
        id="read-less"
        class="lsb lsb-pt-2 lsb-pb-4 lsb-hidden lsb-inline-block lsb-text-slate-400 hover:lsb-text-indigo-700 lsb-cursor-pointer"
      >
        <.fa_icon name="caret-down" style={:thin} plan={@fa_plan} class="lsb-mr-1" /> Read less
      </a>
      <div id="doc-next" class="lsb-hidden lsb-space-y-4 ">
        <%= for paragraph <- Enum.slice(@doc, 1..-1) do %>
          <div class="lsb lsb-text-sm md:lsb-text-base lsb-leading-7 lsb-text-slate-700">
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
    <div class="lsb lsb-flex lsb-flex-items-center">
      <!-- mobile version of navigation tabs -->
      <.form
        :let={f}
        for={:navigation}
        id={"#{Macro.underscore(@story)}-navigation-form"}
        class="lsb story-nav-form lg:lsb-hidden"
      >
        <%= select(f, :tab, navigation_select_options(@tabs),
          "phx-change": "set-tab",
          class:
            "lsb lsb-form-select lsb-w-full lsb-pl-3 lsb-pr-10 lsb-py-1 lsb-text-base lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-600 focus:lsb-border-indigo-600 sm:lsb-text-sm lsb-rounded-md",
          value: @tab
        ) %>
      </.form>
      <!-- :lg+ version of navigation tabs -->
      <nav class="lsb story-tabs lsb-hidden lg:lsb-flex lsb-rounded-lg lsb-border lsb-bg-slate-100 lsb-hover:lsb-bg-slate-200 lsb-h-10 lsb-text-sm lsb-font-medium">
        <%= for tab <- @tabs do %>
          <% {tab_id, tab_label} = {elem(tab, 0), elem(tab, 1)} %>
          <a
            href="#"
            phx-click="set-tab"
            phx-value-tab={tab_id}
            class={"lsb lsb-group focus:lsb-outline-none lsb-flex lsb-rounded-md #{active_link(@tab, tab_id)}"}
          >
            <span class={active_span(@tab, tab_id)}>
              <% icon = if tuple_size(tab) == 3, do: elem(tab, 2), else: nil %>
              <%= if icon do %>
                <.user_icon
                  icon={icon}
                  class={"lg:lsb-mr-2 group-hover:lsb-text-indigo-600 #{active_text(@tab, tab_id)}"}
                  fa_plan={@fa_plan}
                />
              <% end %>
              <span class={"lsb lsb-whitespace-nowrap group-hover:lsb-text-indigo-600 #{active_text(@tab, tab_id)}"}>
                <%= tab_label %>
              </span>
            </span>
          </a>
        <% end %>
      </nav>
    </div>
    """
  end

  defp active_link(same, same), do: "lsb lsb-bg-white lsb-opacity-100"

  defp active_link(_tab, _current_tab) do
    "lsb lsb-ml-0.5 lsb-p-1.5 lg:lsb-pl-2.5 lg:lsb-pr-3.5 lsb-items-center lsb-text-slate-600"
  end

  defp active_span(same, same) do
    "lsb lsb-h-full lsb-rounded-md lsb-flex lsb-items-center lsb-bg-white lsb-shadow-sm \
    lsb-ring-opacity-5 lsb-text-indigo-600 lsb-p-1.5 lg:lsb-pl-2.5 lg:lsb-pr-3.5"
  end

  defp active_span(_tab, _current_tab), do: ""

  defp active_text(same, same), do: "lsb-text-indigo-600"
  defp active_text(_tab, _current_tab), do: "-lsb-ml-0.5"

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
            _ -> []
          end
      )

    ~H"""
    <div class="lsb  lsb-space-y-12 lsb-pb-12" id={"story-variations-#{story_id(@story)}"}>
      <%= for variation = %{id: variation_id, description: description} <- @story.variations(),
              extra_attributes = ExtraAssignsHelpers.variation_extra_attributes(variation, assigns),
              rendering_context = RenderingContext.build(assigns.story, variation, extra_attributes) do %>
        <div
          id={anchor_id(variation)}
          class="lsb lsb-variation-block lsb-gap-x-4 lsb-grid lsb-grid-cols-5"
        >
          <!-- Variation description -->
          <div class="lsb lsb-col-span-5 lsb-font-medium hover:lsb-font-semibold lsb-mb-6 lsb-border-b lsb-border-slate-100 md:lsb-text-lg lsb-leading-7 lsb-text-slate-700 lsb-flex lsb-justify-between">
            <%= link to: "##{anchor_id(variation)}", class: "lsb variation-anchor-link" do %>
              <.fa_icon
                style={:light}
                name="link"
                class="lsb-hidden -lsb-ml-8 lsb-pr-1 lsb-text-slate-400"
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
              class="lsb lsb-hidden lsb-open-playground-link"
            >
              <span class="lsb lsb-text-base lsb-font-light lsb-text-gray-500 hover:lsb-text-indigo-600 hover:lsb-font-medium ">
                Open in playground <.fa_icon style={:regular} name="arrow-right" plan={@fa_plan} />
              </span>
            </.link>
          </div>
          <!-- Variation component preview -->
          <div class="lsb lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lsb-mb-4 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-p-2 lsb-bg-white lsb-shadow-sm">
            <%= if @story.container() == :iframe do %>
              <iframe
                phx-update="ignore"
                id={iframe_id(@story, variation)}
                src={
                  path_to_iframe(@socket, @root_path, @story_path,
                    variation_id: variation.id,
                    theme: @theme
                  )
                }
                class="lsb-w-full lsb-border-0"
                height="0"
                onload="javascript:(function(o){o.style.height=o.contentWindow.document.body.scrollHeight+'px';}(this));"
              />
            <% else %>
              <div
                class={LayoutView.sandbox_class(@socket, @story.container(), assigns)}
                {@sandbox_attributes}
              >
                <%= ComponentRenderer.render(rendering_context) %>
              </div>
            <% end %>
          </div>
          <!-- Variation code -->
          <div class="lsb lsb-border lsb-border-slate-100 lsb-bg-slate-800 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-3 lsb-group lsb-relative lsb-shadow-sm lsb-flex lsb-flex-col lsb-justify-center">
            <div
              phx-click={JS.dispatch("lsb:copy-code")}
              class="lsb lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer"
            >
              <.fa_icon name="copy" class="lsb-text-inherit" plan={@fa_plan} />
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
    <div class="lsb lsb-flex-1 lsb-flex lsb-flex-col lsb-overflow-auto lsb-max-h-full">
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
    <div class={LayoutView.sandbox_class(@socket, {:div, class: "lsb lsb-pb-12"}, assigns)}>
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
         class: LayoutView.sandbox_class(assigns.socket, {:div, class: "lsb lsb-pb-12"}, assigns)}
    )
  end

  defp render_content(:example, assigns = %{tab: :source}) do
    ~H"""
    <div class="lsb lsb-flex-1 lsb-flex lsb-flex-col lsb-overflow-auto lsb-max-h-full">
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
        <div class="lsb lsb-flex-1 lsb-flex lsb-flex-col lsb-overflow-auto lsb-max-h-full">
          <%= @source |> CodeRenderer.render_source() |> to_raw_html() %>
        </div>
        """
    end
  end

  # removing Storybook's specific not useful while reading example's source code.
  defp remove_example_code(code) do
    code
    # removing specifc storybook use
    |> String.replace(~r|use\s+PhxLiveStorybook\.Story\s*,\s*:example|, "use Phoenix.LiveView")
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

  def handle_event("set-theme", %{"theme" => theme}, socket) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      socket.assigns.playground_topic,
      {:set_theme, String.to_atom(theme)}
    )

    ThemeHelpers.call_theme_function(socket.assigns.backend_module, theme)

    {:noreply,
     socket
     |> assign(:theme, theme)
     |> patch_to(socket.assigns.root_path, socket.assigns.story_path, %{theme: theme})}
  end

  def handle_event("set-tab", %{"tab" => tab}, socket) do
    {:noreply, patch_to(socket, socket.assigns.root_path, socket.assigns.story_path, %{tab: tab})}
  end

  def handle_event("set-tab", %{"navigation" => %{"tab" => tab}}, socket) do
    {:noreply, patch_to(socket, socket.assigns.root_path, socket.assigns.story_path, %{tab: tab})}
  end

  def handle_event("clear-playground-error", _, socket) do
    {:noreply, assign(socket, :playground_error, nil)}
  end

  def handle_event("assign", assign_params, socket = %{assigns: assigns}) do
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

  def handle_event("toggle", assign_params, socket = %{assigns: assigns}) do
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

  def handle_info({:playground_preview_pid, pid}, socket) do
    Process.monitor(pid)

    {:noreply, assign(socket, :playground_preview_pid, pid)}
  end

  def handle_info({:component_iframe_pid, pid}, socket) do
    PubSub.subscribe(PhxLiveStorybook.PubSub, "event_logs:#{inspect(pid)}")
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

defmodule PhxLiveStorybook.StoryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.StoryTabNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
