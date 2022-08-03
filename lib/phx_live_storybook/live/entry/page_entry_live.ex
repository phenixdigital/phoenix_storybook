defmodule PhxLiveStorybook.Entry.PageEntryLive do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  @doc false
  def render(assigns) do
    ~H"""
    <div class="lsb-pb-12">
      <%= raw(@backend_module.render_page(@entry.module, @tab)) %>
    </div>
    """
  end

  @doc false
  def navigation_tabs(%{entry: entry}) do
    entry.navigation()
  end

  @doc false
  def default_tab(entry) do
    case entry.navigation() do
      [] -> nil
      [{tab, _, _} | _] -> tab
    end
  end
end
