defmodule PhxLiveStorybook.NavigationHelpers do
  @moduledoc false

  alias Phoenix.LiveView
  alias PhxLiveStorybook.StorybookHelpers

  def patch_to(socket, story_path, params \\ %{}) do
    path = path_to(socket, story_path, params)
    LiveView.push_patch(socket, to: path)
  end

  def path_to(socket = %{assigns: assigns}, story_path, params) do
    query =
      assigns
      |> Map.take([:theme, :tab, :variation_id])
      |> Map.merge(params)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    story_path = StorybookHelpers.live_storybook_path(socket, :story, Path.split(story_path))

    if Enum.any?(query) do
      story_path <> "?" <> URI.encode_query(query)
    else
      story_path
    end
  end
end
