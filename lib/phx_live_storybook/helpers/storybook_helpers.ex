defmodule PhxLiveStorybook.StorybookHelpers do
  @moduledoc false

  def routes(conn = %Plug.Conn{}) do
    conn.private.application_router.__helpers__()
  end

  def routes(socket = %Phoenix.LiveView.Socket{}) do
    socket.router.__helpers__()
  end
end
