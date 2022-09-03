defmodule PhxLiveStorybook.EntryLive do
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.{LiveView.JS, PubSub}
  alias PhxLiveStorybook.{ComponentEntry, PageEntry}
  alias PhxLiveStorybook.Entry.Playground
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.{EntryNotFound, EntryTabNotFound}
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.{Story, StoryGroup}

  import PhxLiveStorybook.NavigationHelpers

  @topic "playground"

  def mount(_params, session, socket) do
    if connected?(socket) do
      PubSub.subscribe(PhxLiveStorybook.PubSub, @topic)
    end

    {:ok,
     assign(socket,
       otp_app: session["otp_app"],
       backend_module: session["backend_module"],
       assets_path: session["assets_path"],
       playground_error: nil,
       playground_preview_pid: nil
     )}
  end

  def handle_params(params, _uri, socket) when params == %{} do
    case first_component_entry(socket) do
      nil -> {:noreply, socket}
      entry -> {:noreply, patch_to(socket, entry)}
    end
  end

  def handle_params(params = %{"entry" => entry_path}, _uri, socket) do
    case load_entry(socket, entry_path) do
      nil ->
        raise EntryNotFound, "unknown entry #{inspect(entry_path)}"

      entry ->
        {:noreply,
         assign(socket,
           entry: entry,
           entry_path: entry_path,
           story: current_story(entry, params),
           page_title: entry.name,
           tab: current_tab(params, entry),
           theme: current_theme(params, socket),
           story_extra_assigns: init_story_extra_assigns(entry),
           playground_error: nil
         )
         |> push_event("lsb:close-sidebar", %{"id" => "#sidebar"})}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp first_component_entry(socket) do
    socket.assigns.backend_module.all_leaves() |> Enum.at(0)
  end

  defp load_entry(socket, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    socket.assigns.backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp current_story(%ComponentEntry{stories: stories}, %{"story_id" => story_id}) do
    Enum.find(stories, &(to_string(&1.id) == story_id))
  end

  defp current_story(%ComponentEntry{stories: [story | _]}, _), do: story
  defp current_story(_, _), do: nil

  defp current_tab(params, entry) do
    case Map.get(params, "tab") do
      nil -> default_tab(entry)
      tab -> String.to_atom(tab)
    end
  end

  defp default_tab(%ComponentEntry{}), do: :stories
  defp default_tab(%PageEntry{navigation: []}), do: nil
  defp default_tab(%PageEntry{navigation: [{tab, _, _} | _]}), do: tab

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

  defp init_story_extra_assigns(%ComponentEntry{stories: stories}) do
    extra_assigns = for %Story{id: story_id} <- stories, into: %{}, do: {story_id, %{}}

    for %StoryGroup{id: group_id, stories: stories} <- stories,
        %Story{id: story_id} <- stories,
        into: extra_assigns,
        do: {{group_id, story_id}, %{}}
  end

  defp init_story_extra_assigns(_), do: nil

  def render(assigns = %{entry: _entry}) do
    ~H"""
    <div class="lsb lsb-space-y-6 lsb-pb-12 lsb-flex lsb-flex-col lsb-h-[calc(100vh_-_7rem)] lg:lsb-h-[calc(100vh_-_4rem)]" id="entry-live" phx-hook="EntryHook">
      <div class="lsb">
        <div class="lsb lsb-flex lsb-my-6 lsb-items-center">
          <h2 class="lsb lsb-flex-1 lsb-flex-nowrap lsb-whitespace-nowrap lsb-text-xl md:lsb-text-2xl lg:lsb-text-3xl lsb-m-0 lsb-font-extrabold lsb-tracking-tight lsb-text-indigo-600">
            <%= if icon = @entry.icon do %>
              <i class={"lsb #{icon} lsb-pr-2 lsb-text-indigo-600"}></i>
            <% end %>
            <%= @entry.name() %>
          </h2>

          <%=  @entry |> navigation_tabs() |> render_navigation_tabs(assigns) %>
        </div>
        <div class="lsb lsb-text-base md:lsb-text-lg lsb-leading-7 lsb-text-slate-700">
          <%= @entry.description() %>
        </div>
      </div>

      <%= render_content(@entry, assigns) %>
    </div>
    """
  end

  def render(assigns), do: ~H""

  defp navigation_tabs(%ComponentEntry{}) do
    [
      {:stories, "Stories", "far fa-eye"},
      {:playground, "Playground", "far fa-dice"},
      {:source, "Source", "far fa-file-code"}
    ]
  end

  defp navigation_tabs(%PageEntry{navigation: navigation}), do: navigation

  defp render_navigation_tabs([], assigns), do: ~H""

  defp render_navigation_tabs(tabs, assigns) do
    ~H"""
    <div class="lsb lsb-flex lsb-flex-items-center">
      <!-- mobile version of navigation tabs -->
      <.form let={f} for={:navigation} id={"#{Macro.underscore(@entry.module)}-navigation-form"} class="lsb entry-nav-form lg:lsb-hidden">
        <%= select f, :tab, navigation_select_options(tabs), "phx-change": "set-tab", class: "lsb lsb-form-select lsb-w-full lsb-pl-3 lsb-pr-10 lsb-py-1 lsb-text-base lsb-border-gray-300 focus:lsb-outline-none focus:lsb-ring-indigo-600 focus:lsb-border-indigo-600 sm:lsb-text-sm lsb-rounded-md", value: @tab %>
      </.form>

      <!-- :lg+ version of navigation tabs -->
      <nav class="lsb entry-tabs lsb-hidden lg:lsb-flex lsb-rounded-lg lsb-border lsb-bg-slate-100 lsb-hover:lsb-bg-slate-200 lsb-h-10 lsb-text-sm lsb-font-medium">
        <%= for {tab, label, icon} <- tabs do %>
          <a href="#" phx-click="set-tab" phx-value-tab={tab} class={"lsb lsb-group focus:lsb-outline-none lsb-flex lsb-rounded-md #{active_link(@tab, tab)}"}>
            <span class={active_span(@tab, tab)}>
              <i class={"lsb #{icon} lg:lsb-mr-2 group-hover:lsb-text-indigo-600 #{active_text(@tab, tab)}"}></i>
              <span class={"lsb group-hover:lsb-text-indigo-600 #{active_text(@tab, tab)}"}>
                <%= label %>
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
  defp active_text(_tab, _current_tab), do: "lsb -lsb-ml-0.5"

  defp navigation_select_options(tabs) do
    for {tab, label, _icon} <- tabs, do: {label, tab}
  end

  defp render_content(entry = %ComponentEntry{}, assigns = %{tab: :stories}) do
    ~H"""
    <div class="lsb lsb-space-y-12 lsb-pb-12">
      <%= for story = %{id: story_id, description: description} <- @entry.stories(),
              story_extra_assigns = story_extra_assigns(story, assigns) do %>
        <div id={anchor_id(story)} class="lsb lsb-group lsb-gap-x-4 lsb-grid lsb-grid-cols-5">

          <!-- Story description -->
          <div class="lsb lsb-col-span-5 lsb-font-medium hover:lsb-font-semibold lsb-mb-6 lsb-border-b lsb-border-slate-100 md:lsb-text-lg lsb-leading-7 lsb-text-slate-700 lsb-group lsb-flex lsb-justify-between">
            <%= link to: "##{anchor_id(story)}", class: "lsb entry-anchor-link" do %>
              <i class="lsb fal fa-link lsb-hidden group-hover:lg:lsb-inline -lsb-ml-8 lsb-pr-1 lsb-text-slate-400"></i>
              <%= if description do %>
                <%= description  %>
              <% else %>
                <%= story_id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            <% end %>
            <%= live_patch to: path_to(@socket, entry, %{tab: :playground, story_id: story.id}), class: "lsb lsb-group lsb-hidden md:group-hover:lsb-inline-block" do %>
              <span class="lsb lsb-text-base lsb-font-light lsb-text-gray-300 hover:lsb-text-indigo-600 hover:lsb-font-medium ">
                Open in playground
                <i class="far fa-arrow-right"></i>
              </span>
            <% end %>
          </div>

          <!-- Story component preview -->
          <div class="lsb lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lsb-mb-4 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-p-2 lsb-bg-white lsb-shadow-sm">
            <%= if @entry.container() == :iframe do %>
              <iframe
                phx-update="ignore"
                id={iframe_id(@entry, story)}
                src={live_storybook_path(@socket, :entry_iframe, @entry_path, story_id: story.id, theme: @theme)}
                class="lsb-w-full lsb-border-0"
                height="0"
                onload="javascript:(function(o){o.style.height=o.contentWindow.document.body.scrollHeight+'px';}(this));"
              />
            <% else %>
              <div class={LayoutView.sandbox_class(assigns)}>
                <%= @backend_module.render_story(@entry.module(), story_id, story_extra_assigns) %>
              </div>
            <% end %>
          </div>

          <!-- Story code -->
          <div class="lsb lsb-border lsb-border-slate-100 lsb-bg-slate-800 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-3 lsb-group lsb-relative lsb-shadow-sm lsb-flex lsb-flex-col lsb-justify-center">
            <div phx-click={JS.dispatch("lsb:copy-code")} class="lsb lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer">
              <i class="lsb fa fa-copy lsb-text-inherit"></i>
            </div>
            <%= @backend_module.render_code(@entry.module(), story_id) %>
          </div>

        </div>
      <% end %>
    </div>
    """
  end

  defp render_content(%ComponentEntry{}, assigns = %{tab: :source}) do
    ~H"""
    <div class="lsb lsb-flex-1 lsb-flex lsb-flex-col lsb-overflow-auto lsb-max-h-full">
      <%= @backend_module.render_source(@entry.module) %>
    </div>
    """
  end

  defp render_content(%ComponentEntry{}, assigns = %{tab: :playground}) do
    ~H"""
    <.live_component module={Playground} id="playground"
      entry={@entry} entry_path={@entry_path} backend_module={@backend_module}
      story={@story}
      playground_error={@playground_error}
      theme={@theme}
    />
    """
  end

  defp render_content(%ComponentEntry{}, _assigns = %{tab: tab}),
    do: raise(EntryTabNotFound, "unknown entry tab #{inspect(tab)}")

  defp render_content(%PageEntry{}, assigns) do
    ~H"""
    <div class={"lsb lsb-pb-12 #{LayoutView.sandbox_class(assigns)}"}>
      <%= raw(@backend_module.render_page(@entry.module, @tab)) %>
    </div>
    """
  end

  defp story_extra_assigns(%Story{id: story_id}, assigns) do
    assigns.story_extra_assigns
    |> Map.get(story_id, %{})
    |> Map.put(:theme, assigns.theme)
  end

  defp story_extra_assigns(%StoryGroup{id: group_id}, assigns) do
    for {{^group_id, story_id}, extra_assigns} <- assigns.story_extra_assigns, into: %{} do
      {story_id, Map.merge(extra_assigns, %{id: "#{group_id}-#{story_id}", theme: assigns.theme})}
    end
    |> Map.put(:theme, assigns.theme)
  end

  defp iframe_id(entry, story) do
    module = entry.module |> Macro.underscore() |> String.replace("/", "_")
    "iframe-#{module}-story-#{story.id}"
  end

  defp anchor_id(%{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end

  def handle_event("set-theme", %{"theme" => theme}, socket) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      @topic,
      {:new_theme, self(), String.to_atom(theme)}
    )

    {:noreply, patch_to(socket, socket.assigns.entry, %{theme: theme})}
  end

  def handle_event("set-tab", %{"tab" => tab}, socket) do
    {:noreply, patch_to(socket, socket.assigns.entry, %{tab: tab})}
  end

  def handle_event("set-tab", %{"navigation" => %{"tab" => tab}}, socket) do
    {:noreply, patch_to(socket, socket.assigns.entry, %{tab: tab})}
  end

  def handle_event("clear-playground-error", _, socket) do
    {:noreply, assign(socket, :playground_error, nil)}
  end

  def handle_event("set-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {story_id, story_extra_assigns} =
      ExtraAssignsHelpers.handle_set_story_assign(
        assign_params,
        assigns.story_extra_assigns,
        assigns.entry
      )

    story_extra_assigns = %{assigns.story_extra_assigns | story_id => story_extra_assigns}
    {:noreply, assign(socket, :story_extra_assigns, story_extra_assigns)}
  end

  def handle_event("toggle-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {story_id, story_extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_story_assign(
        assign_params,
        assigns.story_extra_assigns,
        assigns.entry
      )

    story_extra_assigns = %{assigns.story_extra_assigns | story_id => story_extra_assigns}
    {:noreply, assign(socket, :story_extra_assigns, story_extra_assigns)}
  end

  def handle_info({:playground_preview_pid, pid}, socket) do
    Process.monitor(pid)
    {:noreply, assign(socket, :playground_preview_pid, pid)}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, socket)
      when socket.assigns.playground_preview_pid == pid do
    {:noreply, assign(socket, :playground_error, reason)}
  end

  def handle_info({:new_attributes, pid, attrs}, socket = %{assigns: assigns})
      when pid == assigns.playground_preview_pid do
    send_update(Playground, id: "playground", new_attributes: attrs)
    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end

defmodule PhxLiveStorybook.EntryNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.EntryTabNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
