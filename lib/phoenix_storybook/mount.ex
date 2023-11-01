defmodule PhoenixStorybook.Mount do
  @moduledoc false

  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, session, socket) do
    socket =
      assign(socket,
        backend_module: Map.fetch!(session, "backend_module"),
        root_path: Map.fetch!(session, "root_path"),
        assets_path: Map.fetch!(session, "assets_path"),
        csp_nonces: Map.fetch!(session, "csp_nonces"),
        csrf: Map.fetch!(session, "csrf"),
        live_socket_path: Map.fetch!(session, "live_socket_path")
      )

    {:cont, socket}
  end
end
