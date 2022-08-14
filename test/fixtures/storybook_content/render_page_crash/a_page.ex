defmodule RenderPageCrashStorybook.APage do
  use PhxLiveStorybook.Entry, :page

  def render(_assigns) do
    raise "crash"
  end
end
