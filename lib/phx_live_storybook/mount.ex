defmodule PhxLiveStorybook.Mount do
  @moduledoc false

  def on_mount(:default, _params, session, socket) do
    socket = Phoenix.Component.assign(socket, root_path: Map.fetch!(session, "root_path"))
    {:cont, socket}
  end
end
