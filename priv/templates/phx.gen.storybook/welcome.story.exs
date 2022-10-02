defmodule Storybook.MyPage do
  # See https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.Story.html for full story
  # documentation.
  use PhxLiveStorybook.Story, :page

  def description, do: "Your very first steps into using Phoenix Storybook"

  # Declare an optional tab-based navigation in your page:
  def navigation do
    [
      {:welcome, "Welcome", {:fa, "hand-wave", :thin}},
      {:components, "Components", {:fa, "toolbox", :thin}},
      {:sandboxing, "Sandboxing", {:fa, "box-check", :thin}},
      {:icons, "Icons", {:fa, "icons", :thin}}
    ]
  end

  # This is a dummy fonction that you should replace with your own HEEx content.
  def render(assigns = %{tab: :welcome}) do
    ~H"""
    <div class="lsb-welcome-page">
      <p>
        We generated your storybook with an example of a page and a component.
        Feel free to explore the generated <code class="inline">*.story.exs</code> files generated into your
        project folder, and start adding yours: <strong>just drop new story & index files into your
        </strong><code class="inline">/storybook</code> <strong>folder</strong> and refresh your storybook.
      </p>

      <p>
        Here are a few docs you might be interested in:
      </p>

      <.description_list items={[
        {"Stories overview", doc_link("Story")},
        {"Describe components with Variations", doc_link("Stories.Variation")},
        {"And stack them with VariationGroups", doc_link("Stories.VariationGroup")},
        {"Pimp your sidebar with Index files", doc_link("Index")},
      ]}/>

      <p>
        This should be enough to get you started but you might also <strong>checkout advanced guides
        </strong>(tabs in the upper-right corner of this page).
      </p>
    </div>
    """
  end

  def render(assigns = %{tab: guide}) when guide in ~w(components sandboxing icons)a do
    assigns =
      assign(assigns,
        guide: guide,
        guide_content: PhxLiveStoryBook.Guides.markup("#{guide}.md")
      )

    ~H"""
    <p class="md:lsb-text-lg lsb-leading-relaxed lsb-text-slate-400 lsb-w-full lsb-text-left lsb-mb-4 lsb-mt-2 lsb-italic">
      <a class="hover:text-indigo-700" href={"https://hexdocs.pm/phx_live_storybook/#{@guide}.html"} target="_blank">
        This guide is also available on Hexdocs among others.
      </a>
    </p>
    <div class="lsb-welcome-page lsb-border-t lsb-border-gray-200 lsb-pt-4">
      <%= Phoenix.HTML.raw(@guide_content) %>
    </div>
    """
  end

  defp description_list(assigns) do
    ~H"""
    <div class="lsb-w-full md:lsb-px-8">
      <div class="md:lsb-border-t lsb-border-gray-200 lsb-px-4 lsb-py-5 sm:lsb-p-0 md:lsb-my-6 lsb-w-full">
        <dl class="sm:lsb-divide-y sm:lsb-divide-gray-200">
          <%= for {dt, link} <- @items do %>
            <div class="lsb-py-4 sm:lsb-grid sm:lsb-grid-cols-3 sm:lsb-gap-4 sm:lsb-py-5 sm:lsb-px-6 lsb-max-w-full">
              <dt class="lsb-text-base lsb-font-medium lsb-text-indigo-700">
                <%= dt %>
              </dt>
              <dd class="lsb-mt-1 lsb-text-base lsb-text-slate-400 sm:lsb-col-span-2 sm:lsb-mt-0 lsb-group lsb-cursor-pointer lsb-max-w-full">
                <a class="group-hover:lsb-text-indigo-700 lsb-max-w-full lsb-inline-block lsb-truncate" href={link} target="_blank" %>
                  <%= link %>
                </a>
              </dd>
            </div>
          <% end %>
        </dl>
      </div>
    </div>
    """
  end

  defp doc_link(page) do
    "https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.#{page}.html"
  end
end
