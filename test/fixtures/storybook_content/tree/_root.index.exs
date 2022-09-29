defmodule TreeStorybook.Root do
  use PhxLiveStorybook.Index

  def folder_name, do: "Root"

  def entry("a_page"), do: [icon: {:fa, "page"}]
  def entry("live_component"), do: [name: "Live Component (root)"]
end
