ExUnit.start()

defmodule PhxLiveStorybook.EmptyFilesStorybook do
  use PhxLiveStorybook,
    otp_app: :phx_live_storybook,
    content_path: Path.expand("./fixtures/storybook_content/empty_files", __DIR__)
end

defmodule PhxLiveStorybook.EmptyFoldersStorybook do
  use PhxLiveStorybook,
    otp_app: :phx_live_storybook,
    content_path: Path.expand("./fixtures/storybook_content/empty_folders", __DIR__)
end

defmodule PhxLiveStorybook.FlatListStorybook do
  use PhxLiveStorybook,
    otp_app: :phx_live_storybook,
    content_path: Path.expand("./fixtures/storybook_content/flat_list", __DIR__)
end

defmodule PhxLiveStorybook.TreeStorybook do
  use PhxLiveStorybook,
    otp_app: :phx_live_storybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy
end

defmodule PhxLiveStorybook.TreeBStorybook do
  use PhxLiveStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree_b", __DIR__)
end

defmodule PhxLiveStorybook.TestStorybook do
  use PhxLiveStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    themes: [
      default: [name: "Default"],
      colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
    ],
    themes_strategies: [
      sandbox_class: "theme-prefix",
      assign: :theme
    ]
end

defmodule PhxLiveStorybook.TestRouter do
  use Phoenix.Router
  import PhxLiveStorybook.Router

  storybook_assets()

  live_storybook("/storybook",
    otp_app: :phx_live_storybook,
    backend_module: PhxLiveStorybook.TestStorybook
  )

  scope "/admin" do
    live_storybook("/storybook",
      otp_app: :phx_live_storybook,
      backend_module: PhxLiveStorybook.TestStorybook,
      session_name: :live_storybook_admin,
      as: :admin_live_storybook,
      pipeline: false
    )
  end
end

for endpoint <- [
      PhxLiveStorybook.AssetNotFoundControllerEndpoint,
      PhxLiveStorybook.ComponentIframeLiveEndpoint,
      PhxLiveStorybook.StoryLiveTestEndpoint,
      PhxLiveStorybook.PlaygroundLiveTestEndpoint,
      PhxLiveStorybook.VisualTestLiveEndpoint
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
