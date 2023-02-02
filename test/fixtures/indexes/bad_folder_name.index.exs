defmodule Storybook.BadFolderName do
  use PhoenixStorybook.Index
  def folder_icon, do: {:fa, "book-open", :light}
  def folder_name, do: :storybook

  def entry("colors"), do: [icon: {:fa, "swatchbook", :thin}]
  def entry("typography"), do: [icon: {:fa, "text-size", :duotone}]
end
