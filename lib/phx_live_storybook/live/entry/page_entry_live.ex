defmodule PhxLiveStorybook.Entry.PageEntryLive do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  @doc false
  def render(assigns) do
    ~H"""
    <div class="lsb-pb-12">
      <.live_component id={@entry_module.name()} module={@entry_module} tab={@tab}/>
    </div>
    """
  end

  @doc false
  def navigation_tabs(%{entry_module: entry_module}) do
    entry_module.navigation()
  end

  @doc false
  def default_tab(entry_module) do
    case entry_module.navigation() do
      [] -> nil
      [{tab, _, _} | _] -> tab
    end
  end
end
