ExUnit.start()

for module <- [
      PhxLiveStorybook.EmptyFilesStorybook,
      PhxLiveStorybook.EmptyFoldersStorybook,
      PhxLiveStorybook.FlatListStorybook,
      PhxLiveStorybook.NoContentStorybook,
      PhxLiveStorybook.TestStorybook,
      PhxLiveStorybook.TreeStorybook,
      PhxLiveStorybook.TreeBStorybook
    ] do
  defmodule module do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end
end

defmodule PhxLiveStorybook.TestRouter do
  use Phoenix.Router
  import PhxLiveStorybook.Router

  storybook_assets()

  live_storybook("/storybook",
    otp_app: :phx_live_storybook,
    backend_module: PhxLiveStorybook.TestStorybook
  )
end

for endpoint <- [
      PhxLiveStorybook.EntryLiveTestEndpoint,
      PhxLiveStorybook.PlaygroundLiveTestEndpoint
    ] do
  defmodule endpoint do
    use Phoenix.Endpoint, otp_app: :phx_live_storybook

    plug(Plug.Session,
      store: :cookie,
      key: "_live_view_key",
      signing_salt: "/VEDsdfsffMnp5"
    )

    plug(PhxLiveStorybook.TestRouter)
  end

  Application.put_env(:phx_live_storybook, endpoint,
    url: [host: "localhost", port: 4000],
    secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
    live_view: [signing_salt: "hMegieSe"],
    check_origin: false,
    render_errors: [view: PhxLiveStorybook.ErrorView]
  )
end
