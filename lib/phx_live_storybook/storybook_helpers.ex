defmodule PhxLiveStorybook.Helpers do
  def live_storybook_path(conn_or_socket, action, params \\ %{})

  def live_storybook_path(conn = %Plug.Conn{}, action, params) do
    do_live_storybook_path(conn, conn.private.phoenix_router, action, params)
  end

  def live_storybook_path(socket = %Phoenix.LiveView.Socket{}, action, params) do
    do_live_storybook_path(socket, socket.router, action, params)
  end

  defp do_live_storybook_path(conn_or_socket, router, action, params) do
    apply(
      router.__helpers__(),
      :live_storybook_path,
      [conn_or_socket, action, params]
    )
  end
end
