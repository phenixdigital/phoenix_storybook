import Config

if config_env() == :test do
  # Only intended to silence Phoenix warning:
  #   warning: Phoenix now requires you to explicitly list which engine to use
  #   for Phoenix JSON encoding. We recommend everyone to upgrade to
  #   Jason by setting in your config/config.exs
  config :phoenix, :json_library, Jason

  config :phx_live_storybook, PhxLiveStorybookTest.FlatListStorybook,
    content_path: Path.expand("../test/fixtures/flat_list_content", __DIR__)

  config :phx_live_storybook, PhxLiveStorybookTest.EmptyFilesStorybook,
    content_path: Path.expand("../test/fixtures/empty_files_content", __DIR__)

  config :phx_live_storybook, PhxLiveStorybookTest.EmptyFoldersStorybook,
    content_path: Path.expand("../test/fixtures/empty_folders_content", __DIR__)

  config :phx_live_storybook, PhxLiveStorybookTest.TreeStorybook,
    content_path: Path.expand("../test/fixtures/tree_content", __DIR__)
end
