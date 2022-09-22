defmodule Storybook.BadFolderName do
  use PhxLiveStorybook.Index
  def folder_icon, do: "fal fa-book-open"
  def folder_name, do: :storybook

  def entry("colors"), do: [icon: "fat fa-swatchbook"]
  def entry("typography"), do: [icon: "fad fa-text-size"]
end
