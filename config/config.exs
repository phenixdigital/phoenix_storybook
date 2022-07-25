import Config

if config_env() == :test do
  # Only intended to silence Phoenix warning:
  #   warning: Phoenix now requires you to explicitly list which engine to use
  #   for Phoenix JSON encoding. We recommend everyone to upgrade to
  #   Jason by setting in your config/config.exs
  config :phoenix, :json_library, Jason

  for test_module <- [PhxLiveStorybookTest, PhxLiveStorybook.SidebarTest],
      {storybook_module, content_path, folders} <- [
        {"FlatListStorybook", "flat_list_content", []},
        {"EmptyFilesStorybook", "empty_files_content", []},
        {"EmptyFoldersStorybook", "empty_folders_content", []},
        {"TreeStorybook", "tree_content", [a_folder: [icon: "fa-icon"], b_folder: [open: true]]}
      ] do
    config :phx_live_storybook, :"#{test_module}.#{storybook_module}",
      content_path: Path.expand("../test/fixtures/#{content_path}", __DIR__),
      folders: folders
  end
end
