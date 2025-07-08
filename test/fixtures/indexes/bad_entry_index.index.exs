defmodule Storybook.BadEntryIndex do
  use PhoenixStorybook.Index

  def entry("colors"), do: [index: "0"]

end
