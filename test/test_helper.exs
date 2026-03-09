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
    source_permalink_base_url: "https://github.com/phenixdigital/phoenix_storybook/blob/main",
    themes: [
      default: [name: "Default"],
      colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
    ],
    themes_strategies: [
      sandbox_class: "theme-prefix",
      assign: :theme
    ],
    color_mode: true,
    color_mode_sandbox_light_class: "light",
    strip_doc_attributes: false
end

defmodule PhoenixStorybook.NoSourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy
end

defmodule PhoenixStorybook.EmptySourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    source_permalink_base_url: ""
end

defmodule PhoenixStorybook.GitlabSourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    source_permalink_base_url: "https://gitlab.com/phenixdigital/phoenix_storybook"
end

defmodule PhoenixStorybook.GitlabBlobSourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    source_permalink_base_url: "https://gitlab.com/phenixdigital/phoenix_storybook/-/blob/main"
end

defmodule PhoenixStorybook.UnknownHostSourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    source_permalink_base_url: "https://bitbucket.org/phenixdigital/phoenix_storybook"
end

defmodule PhoenixStorybook.MismatchedRepoSourcePermalinkStorybook do
  use PhoenixStorybook,
    content_path: Path.expand("./fixtures/storybook_content/tree", __DIR__),
    compilation_mode: :lazy,
    source_permalink_base_url: "https://github.com/phenixdigital/another_repo/blob/main"
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

  live_storybook("/storybook_no_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.NoSourcePermalinkStorybook,
    session_name: :live_storybook_no_permalink,
    pipeline: false
  )

  live_storybook("/storybook_empty_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.EmptySourcePermalinkStorybook,
    session_name: :live_storybook_empty_permalink,
    pipeline: false
  )

  live_storybook("/storybook_gitlab_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.GitlabSourcePermalinkStorybook,
    session_name: :live_storybook_gitlab_permalink,
    pipeline: false
  )

  live_storybook("/storybook_gitlab_blob_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.GitlabBlobSourcePermalinkStorybook,
    session_name: :live_storybook_gitlab_blob_permalink,
    pipeline: false
  )

  live_storybook("/storybook_unknown_host_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.UnknownHostSourcePermalinkStorybook,
    session_name: :live_storybook_unknown_host_permalink,
    pipeline: false
  )

  live_storybook("/storybook_mismatched_repo_permalink",
    otp_app: :phoenix_storybook,
    backend_module: PhoenixStorybook.MismatchedRepoSourcePermalinkStorybook,
    session_name: :live_storybook_mismatched_repo_permalink,
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
