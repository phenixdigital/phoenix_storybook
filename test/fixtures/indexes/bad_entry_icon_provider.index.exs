defmodule Storybook.BadEntryIconProvider do
  use PhoenixStorybook.Index
  def folder_icon, do: {:fa, "book-open"}
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: {:unknown, "ufo"}]
end
