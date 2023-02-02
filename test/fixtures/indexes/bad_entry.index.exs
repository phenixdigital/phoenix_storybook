defmodule Storybook.BadEntry do
  use PhoenixStorybook.Index
  def folder_icon, do: {:fa, "book-open"}
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: "fat fa-swatchbook"]
end
