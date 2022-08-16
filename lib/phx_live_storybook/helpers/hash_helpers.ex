defmodule PhxLiveStorybook.HashHelpers do
  @moduledoc false
  def hash(file_content) do
    file_content |> :erlang.md5() |> Base.encode16()
  end
end
