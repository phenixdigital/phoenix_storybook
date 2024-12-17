ExUnit.start()

defmodule PhoenixStorybook.EmptyFilesStorybook do
  use PhoenixStorybook,
    otp_app: :phoenix_storybook,
    content_path: Path.expand("./fixtures/storybook_content/empty_files", __DIR__)
end

defmodule PhoenixStorybook.EmptyFoldersStorybook do
  use PhoenixStorybook,
    otp_app: :phoenix_storybook,
    content_path: Path.expand("./fixtures/storybook_content/empty_folders", __DIR__)
end

defmodule PhoenixStorybook.FlatListStorybook do
  use PhoenixStorybook,
    otp_app: :phoenix_storybook,
    content_path: Path.expand("./fixtures/storybook_content/flat_list", __DIR__)
end

defmodule PhoenixStorybook.TreeStorybook do
  use PhoenixStorybook,
    otp_app: :phoenix_storybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy
end

defmodule PhoenixStorybook.TreeBStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree_b", __DIR__)
end

defmodule PhoenixStorybook.TestStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    themes: [
      default: [name: "Default"],
      colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
    ],
    themes_strategies: [
      sandbox_class: "theme-prefix",
      assign: :theme
    ],
    color_mode: true,
    strip_doc_attributes: false
end

defmodule PhoenixStorybook.TestRouter do
  use Phoenix.Router
  import PhoenixStorybook.Router

  storybook_assets()

  live_storybook("/storybook",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.TestStorybook
  )

  live_storybook("/tree_storybook",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.TreeStorybook,
    session_name: :tree_storybook,
    pipeline: false
  )

  scope "/admin" do
    live_storybook("/storybook",
      otp_app: :phoenix_storybook,
      backend_module: PhoenixStorybook.TestStorybook,
      session_name: :live_storybook_admin,
      as: :admin_live_storybook,
      pipeline: false
    )
  end
end

for endpoint <- [
      PhoenixStorybook.AssetNotFoundControllerEndpoint,
      PhoenixStorybook.ComponentIframeLiveEndpoint,
      PhoenixStorybook.StoryLiveTestEndpoint,
      PhoenixStorybook.PlaygroundLiveTestEndpoint,
      PhoenixStorybook.VisualTestLiveEndpoint
    ] do
  defmodule endpoint do
    use Phoenix.Endpoint, otp_app: :phoenix_storybook

    plug(Plug.Session,
      store: :cookie,
      key: "_live_view_key",
      signing_salt: "/VEDsdfsffMnp5"
    )

    plug(PhoenixStorybook.TestRouter)
  end

  Application.put_env(:phoenix_storybook, endpoint,
    url: [host: "localhost", port: 4000],
    secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
    live_view: [signing_salt: "hMegieSe"],
    check_origin: false,
    render_errors: [view: PhoenixStorybook.ErrorView]
  )
end
