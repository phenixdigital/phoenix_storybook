defmodule AllTypesComponent do
  use Phoenix.Component

  defmodule Struct do
    defstruct [:name]
  end

  def all_types_component(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:option, fn -> nil end)
      |> assign_new(:index_i, fn -> 42 end)
      |> assign_new(:index_i_with_range, fn -> 5 end)
      |> assign_new(:index_f, fn -> 37.2 end)
      |> assign_new(:toggle, fn -> false end)
      |> assign_new(:things, fn -> [] end)
      |> assign_new(:slot_thing, fn -> [] end)
      |> assign_new(:map, fn -> %{} end)

    if assigns[:label] == "raise" do
      raise "booooom!"
    end

    ~H"""
    <div>
      <p>all_types_component: <%= @label %></p>
      <p>option: <%= @option %></p>
      <p>index_i: <%= @index_i %></p>
      <p>index_i_with_range: <%= @index_i_with_range %></p>
      <p>index_f: <%= @index_f %></p>
      <p>toggle: <%= @toggle %></p>
      <p>things: <%= inspect(@things) %></p>
      <p>map: <%= inspect(@map) %></p>
      <%= render_block(@inner_block) %>
      <ul>
      <%= for thing <- @slot_thing do %>
        <li><%= render_slot(thing) %></li>
      <% end %>
      </ul>
    </div>
    """
  end
end
