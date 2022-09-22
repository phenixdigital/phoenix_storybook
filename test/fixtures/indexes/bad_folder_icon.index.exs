defmodule Storybook.BadFolderIcon do
  use PhxLiveStorybook.Index
  def folder_icon, do: :icon
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: "fat fa-swatchbook"]
  def entry("typography"), do: [icon: "fad fa-text-size"]
end
