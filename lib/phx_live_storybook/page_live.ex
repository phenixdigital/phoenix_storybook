defmodule PhxLiveStorybook.PageNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule PhxLiveStorybook.PageLive do
  @moduledoc false
  use PhxLiveStorybook.Web, :live_view

  def render(assigns) do
    ~H"""
    <p class="lsb-text-blue-400">hello world</p>
    """
  end
end
