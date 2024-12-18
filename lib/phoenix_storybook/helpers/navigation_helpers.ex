defmodule PhoenixStorybook.NavigationHelpers do
  @moduledoc false

  alias Phoenix.LiveView

  def patch_to(socket, root_path, story_path, params \\ %{}) do
    path = path_to(socket, root_path, story_path, params)
    LiveView.push_patch(socket, to: path)
  end

  def navigate_to(socket, root_path, story_path, params \\ %{}) do
    path = path_to(socket, root_path, story_path, params)
    LiveView.push_navigate(socket, to: path)
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
      query = query |> Enum.to_list() |> Enum.sort_by(&elem(&1, 0))
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
    |> Enum.to_list()
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  end
end
