defmodule PhxLiveStorybook.Entry.PlaygroundPreviewLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias Phoenix.PubSub
  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.LayoutView
  alias PhxLiveStorybook.Rendering.ComponentRenderer
  alias PhxLiveStorybook.{Story, StoryGroup}
  alias PhxLiveStorybook.TemplateHelpers

  def mount(_params, session, socket) do
    entry = load_entry(String.to_atom(session["backend_module"]), session["entry_path"])

    if connected?(socket) && session["topic"] do
      PubSub.subscribe(PhxLiveStorybook.PubSub, session["topic"])

      PubSub.broadcast!(
        PhxLiveStorybook.PubSub,
        session["topic"],
        {:playground_preview_pid, self()}
      )
    end

    story_or_group = Enum.find(entry.stories, &(&1.id == session["story_id"]))

    {:ok,
     socket
     |> assign(entry: entry, topic: session["topic"], theme: session["theme"])
     |> assign_stories(story_or_group), layout: false}
  end

  defp assign_stories(socket, story_or_group) do
    case story_or_group do
      story = %Story{} -> assign_stories(socket, story, [story])
      group = %StoryGroup{stories: stories} -> assign_stories(socket, group, stories)
      _ -> assign_stories(socket, nil, [])
    end
  end

  defp assign_stories(socket, story_or_group, stories) do
    assign(
      socket,
      counter: 0,
      story: story_or_group,
      story_id: if(story_or_group, do: story_or_group.id, else: nil),
      stories:
        for story <- stories do
          %{
            id: story.id,
            let: story.let,
            block: story.block,
            slots: story.slots,
            attributes:
              Map.merge(
                %{id: "playground-preview-#{story.id}", theme: socket.assigns.theme},
                story.attributes
              )
          }
        end
    )
  end

  def render(assigns) do
    template = TemplateHelpers.get_template(assigns.entry.template, assigns.story)

    ~H"""
    <div id="playground-preview-live" style="height: 100%;">
      <div id={"sandbox-#{@counter}"} class={LayoutView.sandbox_class(assigns)} style="display: flex; flex-direction: column; justify-content: center; align-items: center; margin: 0; gap: 5px; height: 100%; padding: 10px;">
        <%= ComponentRenderer.render_multiple_stories(fun_or_component(@entry), @story, @stories, template, [imports: @entry.imports, aliases: @entry.aliases]) %>
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

  def handle_info({:new_attributes_input, attrs}, socket) do
    stories =
      for story <- socket.assigns.stories do
        new_attrs = story.attributes |> Map.merge(attrs) |> Map.reject(fn {_, v} -> is_nil(v) end)
        %{story | attributes: new_attrs}
      end

    {:noreply, socket |> inc_counter() |> assign(stories: stories)}
  end

  def handle_info({:set_theme, theme}, socket) do
    {:noreply,
     socket
     |> assign(:theme, theme)
     |> assign_stories(socket.assigns.story)}
  end

  def handle_info({:set_story, story}, socket) do
    {:noreply, assign_stories(socket, story)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def handle_event("set-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    stories =
      for story <- assigns.stories do
        {story_id, attrs} =
          ExtraAssignsHelpers.handle_set_story_assign(
            assign_params,
            story.attributes,
            assigns.entry,
            :flat
          )

        if story.id == story_id do
          %{story | attributes: attrs}
        else
          story
        end
      end

    send_stories_attributes(assigns.topic, stories)
    {:noreply, socket |> inc_counter() |> assign(stories: stories)}
  end

  def handle_event("toggle-story-assign/" <> assign_params, _, socket = %{assigns: assigns}) do
    stories =
      for story <- assigns.stories do
        {story_id, attrs} =
          ExtraAssignsHelpers.handle_toggle_story_assign(
            assign_params,
            story.attributes,
            assigns.entry,
            :flat
          )

        if story.id == story_id do
          %{story | attributes: attrs}
        else
          story
        end
      end

    send_stories_attributes(assigns.topic, stories)
    {:noreply, socket |> inc_counter() |> assign(stories: stories)}
  end

  defp send_stories_attributes(topic, stories) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      topic,
      {:new_stories_attributes, Enum.map(stories, &Map.take(&1, [:id, :attributes]))}
    )
  end

  # Some components outside of the liveview world needs an ID update to re-render.
  # It's the case for FontAwesome JS.
  defp inc_counter(socket) do
    assign(socket, :counter, socket.assigns.counter + 1)
  end
end
