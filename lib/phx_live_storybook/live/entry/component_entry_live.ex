defmodule PhxLiveStorybook.Entry.ComponentEntryLive do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  alias PhxLiveStorybook.ComponentEntry
  alias PhxLiveStorybook.Entry.Playground
  alias PhxLiveStorybook.{EntryTabNotFound, Story, StoryGroup}

  def navigation_tabs do
    [
      {:stories, "Stories", "far fa-eye"},
      {:playground, "Playground", "far fa-dice"},
      {:source, "Source", "far fa-file-code"}
    ]
  end

  def default_tab, do: :stories

  def render(assigns = %{tab: :stories}) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pt-8 lsb-pb-12">
      <%= for story = %{id: story_id, description: description} when is_struct(story, Story) or is_struct(story, StoryGroup) <- @entry.stories() do %>
        <div id={anchor_id(story)} class="lsb-gap-x-4 lsb-grid lsb-grid-cols-5">

          <!-- Story description -->
          <div class="lsb-col-span-5 lsb-font-medium hover:lsb-font-semibold lsb-mb-6 lsb-border-b lsb-border-slate-100 lsb-text-lg lsb-leading-7 lsb-text-slate-700 lsb-group">
            <%= link to: "##{anchor_id(story)}", class: "entry-anchor-link" do %>
              <i class="fal fa-link hidden group-hover:lsb-inline -lsb-ml-8 lsb-pr-1 lsb-text-slate-400"></i>
              <%= if description do %>
                <%= description  %>
              <% else %>
                <%= story_id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            <% end %>
          </div>

          <!-- Story component preview -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-2 lsb-mb-4 lg:lsb-mb-0 lsb-flex lsb-items-center lsb-justify-center lsb-p-2 lsb-bg-white lsb-shadow-sm lsb-justify-evenly">
            <%= @backend_module.render_story(@entry.module(), story_id) %>
          </div>

          <!-- Story code -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded-md lsb-col-span-5 lg:lsb-col-span-3 lsb-group lsb-relative lsb-shadow-sm">
            <div class="copy-code-btn lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer">
              <i class="fa fa-copy"></i>
            </div>
            <%= @backend_module.render_code(@entry.module(), story_id) %>
          </div>

        </div>
      <% end %>
    </div>
    """
  end

  def render(assigns = %{tab: :source}) do
    ~H"""
    <div class="lsb-flex-1 lsb-flex lsb-flex-col lsb-overflow-auto lsb-max-h-full">
      <%= @backend_module.render_source(@entry.module) %>
    </div>
    """
  end

  def render(assigns = %{tab: :playground}) do
    ~H"""
    <.live_component module={Playground} id="playground"
      entry={@entry} entry_path={@entry_path} backend_module={@backend_module}
      story={default_story(@entry)}
      playground_preview_pid={@playground_preview_pid}
    />
    """
  end

  def render(_assigns = %{tab: tab}),
    do: raise(EntryTabNotFound, "unknown entry tab #{inspect(tab)}")

  defp default_story(%ComponentEntry{stories: [story | _]}), do: story
  defp default_story(_), do: nil

  defp anchor_id(%{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end
end
