defmodule Storybook.Valid do
  use PhoenixStorybook.Index
  def folder_icon, do: {:fa, "book-open", :light}
  def folder_name, do: "Storybook"

  def entry("colors"), do: [icon: {:fa, "swatchbook", :thin}]
  def entry("typography"), do: [icon: {:fa, "text-size", :duotone}]
  def entry("hero"), do: [icon: {:local, "hero-book-open", "h-2 w-2"}]
end
