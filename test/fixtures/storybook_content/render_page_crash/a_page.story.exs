defmodule RenderPageCrashStorybook.APage do
  use PhoenixStorybook.Story, :page

  def render(_assigns) do
    raise "crash"
  end
end
