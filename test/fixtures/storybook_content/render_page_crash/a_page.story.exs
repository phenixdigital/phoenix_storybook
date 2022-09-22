defmodule RenderPageCrashStorybook.APage do
  use PhxLiveStorybook.Story, :page

  def render(_assigns) do
    raise "crash"
  end
end
