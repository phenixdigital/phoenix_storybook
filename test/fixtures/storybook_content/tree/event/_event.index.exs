defmodule TreeStorybook.Event do
  use PhoenixStorybook.Index

  def folder_index, do: 2

  def entry("event_live_component"), do: [name: "Live Event Component (root)"]
end
