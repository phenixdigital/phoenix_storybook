defmodule PhxLiveStorybook.Components do
  @moduledoc false
  use PhxLiveStorybook.Web, :component

  @doc """
  Intersperses separator slot between a collection of items.

  ## Examples

      <.intersperse items={@breadcrumbs}>
        <:separator>
          <i class="lsb fat fa-angle-right lsb-px-2 lsb-text-slate-500"></i>
        </:separator>
        <:item :let={item}>
          <span class={["lsb", @class, "[&:not(:last-child)]:lsb-truncate"]}><%= item %></span>
        </:item>
      </.intersperse>
  """
  attr(:items, :list, required: true)
  slot(:separator, required: true)
  slot(:item, required: true)

  def intersperse(assigns) do
    ~H"""
    <%= for item <- Enum.intersperse(@items, :separator) do %>
      <%= if item == :separator do %>
        <%= render_slot(@separator) %>
      <% else %>
        <%= render_slot(@item, item) %>
      <% end %>
    <% end %>
    """
  end
end
