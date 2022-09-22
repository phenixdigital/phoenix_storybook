defmodule Storybook.BadEntry do
  use PhxLiveStorybook.Index
  def folder_icon, do: "fal fa-book-open"
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: "fat fa-swatchbook"]
  def entry("typography"), do: [icoon: "fad fa-text-size"]
end
