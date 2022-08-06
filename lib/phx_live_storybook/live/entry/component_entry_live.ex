defmodule PhxLiveStorybook.Entry.ComponentEntryLive do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  alias PhxLiveStorybook.Entry.Playground
  alias PhxLiveStorybook.{EntryTabNotFound, Story, StoryGroup}

  def navigation_tabs do
    [
      {:stories, "Stories", "far fa-eye"},
      {:documentation, "Documentation", "far fa-book"},
      {:source, "Source", "far fa-file-code"}
    ]
  end

  def default_tab, do: :stories

  def render(assigns = %{tab: :stories}) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pt-8">
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

  def render(assigns = %{tab: :documentation}) do
    ~H"""
    <div class="lsb-space-y-12 lsb-pt-8">
      <!-- Component playground -->
      <.live_component module={Playground} id={"#{Macro.underscore(@entry.module)}-playground"}
        entry={@entry} attrs={@playground_attrs}
      />

      <!-- Component properties -->
      <.form for={:playground} let={f} id={"#{Macro.underscore(@entry.module)}-playground-form"} phx-change={"playground-change"}>
        <div class="lsb-mt-8 lsb-flex lsb-flex-col">
          <div class="-lsb-my-2 -lsb-mx-4 lsb-overflow-x-auto md:-lsb-mx-8">
            <div class="lsb-inline-block lsb-min-w-full lsb-py-2 lsb-align-middle md:lsb-px-8">
              <div class="lsb-overflow-hidden lsb-shadow lsb-ring-1 lsb-ring-black lsb-ring-opacity-5 md:lsb-rounded-lg">
                <table class="lsb-min-w-full lsb-divide-y lsb-divide-gray-300">
                  <thead class="lsb-bg-gray-50">
                    <tr>
                      <%= for header <- ~w(Attribute Type Documentation Value) do %>
                        <th scope="col" class="lsb-py-3.5 lsb-px-3 md:lsb-px-6 first:lsb-pl-6 first:lg:lsb-pl-9 lsb-text-left lsb-text-sm lsb-font-semibold lsb-text-gray-900">
                          <%= header %>
                        </th>
                      <% end %>
                    </tr>
                  </thead>
                  <tbody class="lsb-divide-y lsb-divide-gray-200 lsb-bg-white">
                    <%= for attr <- @entry.attributes do %>
                      <tr>
                        <td class="lsb-whitespace-nowrap lsb-pr-3 md:lsb-pr-6 lsb-pl-6 md:lsb-pl-9 lsb-py-4 lsb-text-sm lsb-font-medium lsb-text-gray-900 sm:lsb-pl-6">
                          <%= if attr.required do %>
                            <span class="lsb-hidden md:lsb-inline lsb-group lsb-relative -lsb-ml-[1.85em] lsb-pr-2">
                              <i class="lsb-text-indigo-400 hover:lsb-text-indigo-600 lsb-cursor-pointer fad fa-circle-dot"></i>
                              <span class="lsb-hidden lsb-absolute lsb-top-6 group-hover:lsb-block lsb-z-50 lsb-mx-auto lsb-text-xs lsb-text-indigo-800 lsb-bg-indigo-100 lsb-rounded lsb-px-2 lsb-py-1">
                                Required
                              </span>
                            </span>
                          <% end %>

                          <%= attr.id %>
                        </td>
                        <td class="lsb-whitespace-nowrap lsb-px-3 lg:lsb-px-6 lsb-py-4 lsb-text-sm lsb-text-gray-500">
                          <.type_badge type={attr.type}/>
                        </td>
                        <td class="lsb-whitespace-pre-line lsb-px-3 lg:lsb-px-6 lsb-py-4 lsb-text-sm lsb-text-gray-500"><%=String.trim(attr.doc)%></td>
                        <td class="lsb-whitespace-nowrap lsb-lsb-py-4 lsb-pl-3 lsb-pr-4  lsb-text-sm lsb-font-medium sm:lsb-pr-6">
                          <%= text_input f, attr.id, value: Map.get(@playground_attrs, attr.id), class: "lsb-max-w-lg lsb-block lsb-w-full lsb-shadow-sm focus:lsb-ring-indigo-500 focus:lsb-border-indigo-500 sm:lsb-max-w-xs sm:lsb-text-sm lsb-border-gray-300 lsb-rounded-md" %>
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
    </div>
    """
  end

  def render(_assigns = %{tab: tab}),
    do: raise(EntryTabNotFound, "unknown entry tab #{inspect(tab)}")

  defp type_badge(assigns = %{type: :string}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :atom}) do
    ~H"""
    <span class={"lsb-bg-blue-100 lsb-text-blue-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :boolean}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :integer}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :float}) do
    ~H"""
    <span class={"lsb-bg-green-100 lsb-text-green-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: :list}) do
    ~H"""
    <span class={"lsb-bg-teal-100 lsb-text-teal-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge(assigns = %{type: _type}) do
    ~H"""
    <span class={"lsb-bg-slate-100 lsb-text-slate-800 #{type_badge_class()}"}><%= @type %></span>
    """
  end

  defp type_badge_class do
    "lsb-rounded lsb-px-2 lsb-py-1 lsb-font-mono lsb-text-xs"
  end

  defp anchor_id(%{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end
end
