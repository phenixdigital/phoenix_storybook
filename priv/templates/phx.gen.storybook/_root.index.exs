defmodule Storybook.Root do
  # See https://hexdocs.pm/phx_live_storybook/PhxLiveStorybook.Index.html for full index
  # documentation.

  use PhxLiveStorybook.Index

  def folder_icon, do: {:fa, "book-open", :light, "lsb-mr-1"}
  def folder_name, do: "Storybook"

  def entry("welcome"),
    do: [
      name: "Welcome Page",
      icon: {:fa, "hand-wave", :thin}
    ]
end
