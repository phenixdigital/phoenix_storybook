defmodule PhxLiveStorybook.VisualTestLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  alias PhxLiveStorybook.ExtraAssignsHelpers
  alias PhxLiveStorybook.Rendering.{ComponentRenderer, RenderingContext}
  alias PhxLiveStorybook.StoryEntry
  alias PhxLiveStorybook.StoryNotFound

  import PhxLiveStorybook.NavigationHelpers

  def mount(_params, _session, socket) do
    backend_module = socket.assigns.backend_module

    {:ok,
     assign(socket,
       theme: default_theme(socket),
       fa_plan: backend_module.config(:font_awesome_plan, :free)
     ), layout: {PhxLiveStorybook.LayoutView, :live_iframe}}
  end

  def handle_params(%{"story" => story_path}, _, socket = %{assigns: %{live_action: :show}}) do
    assigns = socket.assigns

    case load_story(assigns, story_path) do
      {:ok, story} ->
        if Enum.member?([:component, :live_component], story.storybook_type()) do
          {:noreply,
           assign(socket,
             stories: [
               %{
                 story: story,
                 entry: story_entry(socket, story_path),
                 path: assigns.backend_module.storybook_path(story),
                 variation_extra_assigns:
                   ExtraAssignsHelpers.init_variation_extra_assigns(story.storybook_type(), story)
               }
             ]
           )}
        else
          raise StoryNotFound, "story #{inspect(story_path)} is not a component story"
        end

      {:error, :not_found} ->
        raise StoryNotFound, "unknown story #{inspect(story_path)}"
    end
  end

  def handle_params(
        %{"start" => start_param, "end" => end_param},
        _,
        socket = %{assigns: %{live_action: :range}}
      ) do
    assigns = socket.assigns
    stories = load_story_range(assigns, [start_param, end_param])
    {:noreply, assign(socket, stories: stories)}
  end

  defp load_story(assigns, story_param) do
    story_path = Path.join(story_param)
    assigns.backend_module.load_story(story_path)
  end

  def load_story_range(assigns, [start_letter, end_letter]) do
    start_char = start_letter |> String.downcase() |> String.to_charlist() |> hd()
    end_char = end_letter |> String.downcase() |> String.to_charlist() |> hd()

    assigns.backend_module.leaves()
    |> Enum.filter(fn %StoryEntry{name: entry_name} ->
      first_char = entry_name |> String.downcase() |> String.to_charlist() |> hd()
      start_char <= first_char && first_char <= end_char
    end)
    |> Enum.map(fn entry = %StoryEntry{path: path} ->
      case path |> String.replace_leading("/", "") |> assigns.backend_module.load_story() do
        {:ok, story} -> {entry, story}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn {_entry, story} ->
      story.storybook_type() in [:component, :live_component]
    end)
    |> Enum.sort_by(fn {entry, _story} -> entry.name end)
    |> Enum.map(fn {entry, story} ->
      %{
        story: story,
        entry: entry,
        path: assigns.backend_module.storybook_path(story),
        variation_extra_assigns:
          ExtraAssignsHelpers.init_variation_extra_assigns(story.storybook_type(), story)
      }
    end)
  end

  defp default_theme(socket) do
    case socket.assigns.backend_module.config(:themes) do
      nil -> nil
      [{theme, _} | _] -> theme
    end
  end

  defp story_entry(socket, story_param) do
    story_path = Path.join(["/" | story_param])
    socket.assigns.backend_module.find_entry_by_path(story_path)
  end

  def render(assigns) do
    ~H"""

    <div
      id={"story-variations-#{story_id(story.story)}"}
      style="width: 650px; margin: 0 auto; margin-top: 40px;"
      :for={story <- @stories}>
      <h1 style="color: #6366f1; padding-bottom: 5px; border-bottom: 1px solid #d1d5db;"><%= story.entry.name %></h1>
      <%= for variation <- story.story.variations(),
              assigns = assign(assigns, variation_extra_assigns: story.variation_extra_assigns, story: story.story),
              extra_attributes = ExtraAssignsHelpers.variation_extra_attributes(variation, assigns),
              rendering_context = RenderingContext.build(story.story, variation, extra_attributes) do %>

        <div style="padding-bottom: 20px;">
          <%= if story.story.container() == :iframe do %>
            <iframe
              phx-update="ignore"
              id={iframe_id(story.story, variation)}
              src={path_to_iframe(@socket, @root_path, story.path, variation_id: variation.id, theme: @theme)}
              height="0"
              onload="javascript:(function(o){o.style.height=o.contentWindow.document.body.scrollHeight+'px';}(this));"
            />
          <% else %>
            <div style="display: flex; gap: 5px;">
              <%= ComponentRenderer.render(rendering_context) %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp iframe_id(story, variation) do
    "iframe-#{story_id(story)}-variation-#{variation.id}"
  end

  defp story_id(story_module) do
    story_module |> Macro.underscore() |> String.replace("/", "_")
  end
end
