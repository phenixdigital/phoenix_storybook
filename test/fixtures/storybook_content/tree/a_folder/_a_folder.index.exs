defmodule TreeStorybook.AFolder do
  use PhxLiveStorybook.Index

  def folder_name, do: "A Folder"
  def folder_icon, do: {:fa, "icon"}

  def entry("component"), do: [name: "Component (a_folder)", icon: {:fa, "icon"}]
  def entry("live_component"), do: [name: "Live Component (a_folder)"]
end
