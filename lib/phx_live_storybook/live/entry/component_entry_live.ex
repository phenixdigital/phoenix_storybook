defmodule PhxLiveStorybook.Entry.ComponentEntryLive do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  alias PhxLiveStorybook.EntryTabNotFound
  alias PhxLiveStorybook.Variation

  def navigation_tabs do
    [
      {:variations, "Variations", "far fa-eye"},
      {:documentation, "Documentation", "far fa-book"},
      {:source, "Source", "far fa-file-code"}
    ]
  end

  def default_tab, do: :variations

  def render(assigns = %{tab: :variations}) do
    ~H"""
    <div class="lsb-space-y-12">
      <%= for variation = %Variation{} <- @entry_module.variations() do %>
        <div id={anchor_id(variation)} class="lsb-gap-x-4 lsb-grid lsb-grid-cols-5">

          <!-- Variation description -->
          <div class="lsb-col-span-5 lsb-font-medium hover:lsb-font-semibold lsb-mb-6 lsb-border-b lsb-border-slate-100 lsb-text-lg lsb-leading-7 lsb-text-slate-700 lsb-group">
            <%= link to: "##{anchor_id(variation)}", class: "entry-anchor-link" do %>
              <i class="fal fa-link hidden group-hover:lsb-inline -lsb-ml-8 lsb-pr-1 lsb-text-slate-400"></i>
              <%= if variation.description do %>
                <%= variation.description  %>
              <% else %>
                <%= variation.id |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
              <% end %>
            <% end %>
          </div>

          <!-- Variation component preview -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-2 lsb-flex lsb-items-center lsb-justify-center lsb-p-2 lsb-bg-white lsb-shadow-sm">
            <%= @backend_module.render_component(@entry_module, variation.id) %>
          </div>

          <!-- Variation code -->
          <div class="lsb-border lsb-border-slate-100 lsb-rounded lsb-col-span-3 lsb-group lsb-relative">
            <div class="copy-code-btn lsb-hidden group-hover:lsb-block lsb-bg-slate-700 lsb-text-slate-500 hover:lsb-text-slate-100 lsb-z-10 lsb-absolute lsb-top-2 lsb-right-2 lsb-px-2 lsb-py-1 lsb-rounded-md lsb-cursor-pointer">
              <i class="fa fa-copy"></i>
            </div>
            <%= @backend_module.render_code(@entry_module, variation.id) %>
          </div>

        </div>
      <% end %>
    </div>
    """
  end

  def render(assigns = %{tab: :documentation}) do
    ~H"""
    <div class="lsb-w-full lsb-text-center lsb-text-slate-400 lsb-pt-20 lsb-px-40">
      <i class="hover:lsb-text-indigo-400 fas fa-traffic-cone fa-5x fa-bounce" style="--fa-animation-iteration-count: 2;"></i>
      <h2 class="lsb-mt-8 lsb-text-lg">Coming soon</h2>
      <p class="lsb-text-left lsb-pt-12 lsb-text-slate-500">
        Here, you'll soon be able to explore your component properties, see their related
        documentation and experiment with them in an interactive playground.
        <br/><br/>
        This will most likely rely on <code>phoenix_live_view 0.18.0</code> declarative assigns feature.
      </p>
    </div>
    """
  end

  def render(assigns = %{tab: :source}) do
    ~H"""
    <%= @backend_module.render_source(@entry_module) %>
    """
  end

  def render(_assigns = %{tab: tab}),
    do: raise(EntryTabNotFound, "unknown entry tab #{inspect(tab)}")

  defp anchor_id(%Variation{id: id}) do
    id |> to_string() |> String.replace("_", "-")
  end
end
