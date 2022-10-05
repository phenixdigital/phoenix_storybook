defmodule PhxLiveStorybook.NavigationHelpers do
  @moduledoc false

  alias Phoenix.LiveView

  def patch_to(socket, root_path, story_path, params \\ %{}) do
    path = path_to(socket, root_path, story_path, params)
    LiveView.push_patch(socket, to: path)
  end

  def path_to(%{assigns: assigns}, root_path, story_path, params) do
    query = build_query(assigns, params)
    build_path(root_path, story_path, query)
  end

  def path_to_iframe(%{assigns: assigns}, root_path, story_path, params) do
    query = build_query(assigns, params)

    root_path
    |> Path.join("iframe")
    |> build_path(story_path, query)
  end

  defp build_path(root_path, story_path, query) do
    path = Path.join(root_path, story_path)

    if Enum.any?(query) do
      path <> "?" <> URI.encode_query(query)
    else
      path
    end
  end

  defp build_query(assigns, params) do
    params = Map.new(params)

    assigns
    |> Map.take([:theme, :tab, :variation_id])
    |> Map.merge(params)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end
end
