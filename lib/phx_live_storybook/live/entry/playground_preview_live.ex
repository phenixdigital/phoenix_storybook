defmodule PhxLiveStorybook.Entry.PlaygroundPreviewLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.Rendering.ComponentRenderer
  alias PhxLiveStorybook.{Story, StoryGroup}

  @topic "playground"
  @component_id "playground-preview"

  def mount(_params, session, socket) do
    entry = load_entry(String.to_atom(session["backend_module"]), session["entry_path"])

    if connected?(socket) do
      PubSub.subscribe(PhxLiveStorybook.PubSub, @topic)
      PubSub.broadcast!(PhxLiveStorybook.PubSub, @topic, {:playground_preview_pid, self()})
    end

    story = find_story(entry.stories, session["story_id"])

    {:ok,
     assign(socket,
       entry: entry,
       attrs: story.attributes,
       block: story.block,
       slots: story.slots,
       parent_pid: session["parent_pid"],
       theme: session["theme"]
     ), layout: false}
  end

  defp find_story(stories, [group_id, story_id]) do
    Enum.find_value(
      stories,
      %{attributes: %{}, block: nil, slots: nil},
      fn
        %StoryGroup{id: id, stories: stories} when id == group_id -> find_story(stories, story_id)
        _ -> nil
      end
    )
  end

  defp find_story(stories, story_id) do
    Enum.find_value(
      stories,
      %{attributes: %{}, block: nil, slots: nil},
      fn
        story = %Story{id: id} when id == story_id -> story
        _ -> nil
      end
    )
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        id: @component_id,
        component_assigns: Map.merge(%{id: @component_id, theme: assigns.theme}, assigns.attrs)
      )

    ~H"""
    <div id="playground-preview-live" style="height: 100%;">
      <div class={LayoutView.sandbox_class(assigns)} style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; height: 100%;">
        <%= if @entry.template do %>
          <%= ComponentRenderer.render_component_within_template(@entry.template, @id, fun_or_component(@entry), @component_assigns, @block, @slots, [imports: @entry.imports, aliases: @entry.aliases]) %>
        <% else %>
          <%= ComponentRenderer.render_component(fun_or_component(@entry), @component_assigns, @block, @slots, [imports: @entry.imports, aliases: @entry.aliases]) %>
        <% end %>
      </div>
    </div>
    """
  end

  defp load_entry(backend_module, entry_param) do
    entry_storybook_path = "/#{Enum.join(entry_param, "/")}"
    backend_module.find_entry_by_path(entry_storybook_path)
  end

  defp fun_or_component(%ComponentEntry{type: :live_component, component: component}),
    do: component

  defp fun_or_component(%ComponentEntry{type: :component, function: function}),
    do: function

  def handle_info({:new_attributes, pid, attrs}, socket = %{assigns: assigns})
      when pid == assigns.parent_pid do
    {:noreply, assign(socket, attrs: attrs)}
  end

  def handle_info({:new_theme, pid, theme}, socket = %{assigns: assigns})
      when pid == assigns.parent_pid do
    {:noreply, assign(socket, theme: theme)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def handle_event("set-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {_story_id, attrs} =
      ExtraAssignsHelpers.handle_set_story_assign(
        assign_params,
        assigns.attrs,
        assigns.entry,
        :flat
      )

    send_attributes(attrs)
    {:noreply, assign(socket, attrs: attrs)}
  end

  def handle_event("toggle-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    {_story_id, attrs} =
      ExtraAssignsHelpers.handle_toggle_story_assign(
        assign_params,
        assigns.attrs,
        assigns.entry,
        :flat
      )

    send_attributes(attrs)
    {:noreply, assign(socket, attrs: attrs)}
  end

  defp send_attributes(attributes) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "playground",
      {:new_attributes, self(), attributes}
    )
  end
end
