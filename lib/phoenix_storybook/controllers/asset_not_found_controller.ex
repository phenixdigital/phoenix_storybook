defmodule PhoenixStorybook.AssetNotFoundController do
  @moduledoc false
  # Dummy controller that only exists because `Plug.Static` requires
  # that a route matches an actual path to be executed.
  #
  # Any valid asset request will halt before this controller is executed.
  # Only bad requests (404) will reach to here.

  use PhoenixStorybook.Web, :controller

  def asset(_conn, path) do
    raise PhoenixStorybook.AssetNotFound, "unknown asset #{inspect(path)}"
  end
end

defmodule PhoenixStorybook.AssetNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end
