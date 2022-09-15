defmodule PhxLiveStorybook.NavigationHelpers do
  @moduledoc false

  alias Phoenix.LiveView
  alias PhxLiveStorybook.StorybookHelpers

  def patch_to(socket, entry, params \\ %{}) do
    path = path_to(socket, entry, params)
    LiveView.push_patch(socket, to: path)
  end

  def path_to(socket = %{assigns: assigns}, entry, params) do
    query =
      assigns
      |> Map.take([:theme, :tab, :story_id])
      |> Map.merge(params)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    entry_path =
      StorybookHelpers.live_storybook_path(
        socket,
        :entry,
        String.split(entry.storybook_path, "/", trim: true)
      )

    if Enum.any?(query) do
      entry_path <> "?" <> URI.encode_query(query)
    else
      entry_path
    end
  end
end
