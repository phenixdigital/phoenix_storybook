defmodule PhxLiveStorybook.Helpers do
  @moduledoc false

  @doc false
  def live_storybook_path(conn_or_socket, action, params \\ %{})

  @doc false
  def live_storybook_path(conn = %Plug.Conn{}, action, params) do
    do_live_storybook_path(conn, conn.private.phoenix_router, action, params)
  end

  @doc false
  def live_storybook_path(socket = %Phoenix.LiveView.Socket{}, action, params) do
    do_live_storybook_path(socket, socket.router, action, params)
  end

  defp do_live_storybook_path(_conn_or_socket, nil, _action, _params), do: ""

  defp do_live_storybook_path(conn_or_socket, router, action, params) do
    router.__helpers__().live_storybook_path(conn_or_socket, action, params)
  end
end
