import Config

for test_module <- [PhxLiveStorybookTest, PhxLiveStorybook.SidebarTest, PhxLiveStorybook.SearchTest],
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
  folders: [a_folder: [open: true]],
  themes: [
    default: [name: "Default"],
    colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
  ]
