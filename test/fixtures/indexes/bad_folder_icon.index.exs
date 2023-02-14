defmodule Storybook.BadFolderIcon do
  use PhoenixStorybook.Index
  def folder_icon, do: :icon
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: {:fa, "swatchbook", :thin}]
  def entry("typography"), do: [icon: {:fa, "text-size", :duotone}]
end
