defmodule PhxLiveStorybook.Router do
  @moduledoc """
  Provides LiveView routing for storybook.
  """

  defmacro live_storybook(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        {session_name, session_opts, route_opts} = PhxLiveStorybook.Router.__options__(opts)
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        live_session session_name, session_opts do
          live("/", PhxLiveStorybook.PageLive, :home, route_opts)
          live("/*page", PhxLiveStorybook.PageLive, :page, route_opts)
        end
      end
    end
  end

  @doc false
  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    {
      :live_storybook,
      [
        root_layout: {PhxLiveStorybook.LayoutView, :storybook}
      ],
      [
        private: %{live_socket_path: live_socket_path},
        as: :live_storybook
      ]
    }
  end
end
