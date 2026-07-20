defmodule PhoenixStorybook.Components.TabNavigation do
  @moduledoc false

  use PhoenixStorybook.Web, :component

  import PhoenixStorybook.Components.Icon

  @doc """
  Renders a tab navigation bar.

  Two variants are supported:

  - `:pills` — a segmented control, used for page-level tabs (next to the story name).
  - `:default` — traditional underlined tabs, used for tabs inside a page's inner segments.

  Tabs are given as tuples, growing from the left:

  - `{id, label}`
  - `{id, label, icon}` where `icon` is a `user_icon/1` config, e.g. `{:fa, "eye", :regular}`
  - `{id, label, icon, suffix}` where `suffix` is extra text appended to the label (or `nil`)
  """

  attr :variant, :atom,
    default: :default,
    values: ~w(default pills)a,
    doc: "`:pills` for page-level tabs, `:default` for inner tabs."

  attr :tabs, :list,
    required: true,
    doc: "Tabs as `{id, label}`, `{id, label, icon}` or `{id, label, icon, suffix}` tuples."

  attr :active, :any, required: true, doc: "Id of the active tab."
  attr :event, :string, required: true, doc: "phx-click event pushed on tab selection."
  attr :target, :any, default: nil, doc: "Optional phx-target for the event."
  attr :fa_plan, :atom, required: true, doc: "FontAwesome plan, forwarded to icons."
  attr :class, :any, default: nil, doc: "Additional CSS classes for the nav element."

  def tab_navigation(assigns) do
    ~H"""
    <nav class={[nav_class(@variant), @class]}>
      <%= for tab <- @tabs do %>
        <% icon = if tuple_size(tab) > 2, do: elem(tab, 2) %>
        <% suffix = if tuple_size(tab) > 3, do: elem(tab, 3) %>
        <a
          href="#"
          phx-click={@event}
          phx-value-tab={elem(tab, 0)}
          phx-target={@target}
          class={[tab_class(@variant), active_class(@variant, elem(tab, 0) == @active)]}
        >
          <.user_icon :if={icon} icon={icon} class={icon_class(@variant)} fa_plan={@fa_plan} />
          <span class="psb psb:leading-none psb:whitespace-nowrap">{elem(tab, 1)}{if suffix, do: " #{suffix}"}</span>
        </a>
      <% end %>
    </nav>
    """
  end

  defp nav_class(:pills) do
    "psb psb:inline-flex psb:h-9 psb:items-center psb:justify-center psb:rounded-lg psb:bg-muted psb:p-1 psb:text-sm psb:font-medium psb:text-muted-foreground"
  end

  defp nav_class(:default) do
    "psb psb:flex psb:items-center psb:gap-4 psb:border-b psb:border-border psb:text-xs psb:font-medium psb:text-muted-foreground psb:md:text-sm"
  end

  defp tab_class(:pills) do
    "psb psb:group psb:inline-flex psb:h-full psb:items-center psb:justify-center psb:whitespace-nowrap psb:rounded-md psb:px-3 psb:py-1 psb:transition-all psb:focus-visible:outline-none psb:focus-visible:ring-1 psb:focus-visible:ring-ring"
  end

  defp tab_class(:default) do
    "psb psb:group psb:inline-flex psb:items-center psb:whitespace-nowrap psb:-mb-px psb:border-b-2 psb:px-1 psb:py-2 psb:transition-colors psb:focus:outline-none"
  end

  defp active_class(:pills, true), do: "psb:bg-background psb:text-foreground psb:shadow-sm"
  defp active_class(:pills, false), do: "psb:hover:text-foreground"
  defp active_class(:default, true), do: "psb:border-primary psb:text-primary"

  defp active_class(:default, false),
    do: "psb:border-transparent psb:hover:text-foreground psb:hover:border-border"

  defp icon_class(:pills), do: "psb:mr-2"
  defp icon_class(:default), do: "psb:mr-1.5"
end
