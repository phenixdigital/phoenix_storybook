import Config

if config_env() == :test do
  # Only intended to silence Phoenix warning:
  #   warning: Phoenix now requires you to explicitly list which engine to use
  #   for Phoenix JSON encoding. We recommend everyone to upgrade to
  #   Jason by setting in your config/config.exs
  config :phoenix, :json_library, Jason

  for test_module <- [PhxLiveStorybookTest, PhxLiveStorybook.SidebarTest],
      {storybook_module, content_path, folders} <- [
        {"FlatListStorybook", "flat_list", []},
        {"EmptyFilesStorybook", "empty_files", []},
        {"EmptyFoldersStorybook", "empty_folders", []},
        {"TreeStorybook", "tree",
         ["/a_folder": [icon: "fa-icon"], "/b_folder": [open: true, name: "Config Name"]]},
        {"TreeBStorybook", "tree_b", []},
        {"RenderComponentCrashStorybook", "render_component_crash", []},
        {"RenderPageCrashStorybook", "render_page_crash", []}
      ] do
    opts = [
      content_path: Path.expand("../test/fixtures/storybook_content/#{content_path}", __DIR__)
    ]

    opts = if Enum.any?(folders), do: Keyword.put(opts, :folders, folders), else: opts
    config :phx_live_storybook, :"#{test_module}.#{storybook_module}", opts
  end

  config :phx_live_storybook, PhxLiveStorybook.TestStorybook,
    content_path: Path.expand("../test/fixtures/storybook_content/tree", __DIR__),
    folders: [a_folder: [open: true]]
end

config :phx_live_storybook, :env, config_env()

config :phoenix, :json_library, Jason
