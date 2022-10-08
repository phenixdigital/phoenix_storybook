defmodule PhxLiveStorybook.Guides.GuidesTest do
  use ExUnit.Case, async: true

  defmodule Guides do
    use PhxLiveStoryBook.Guides.Macros
  end

  test "components guide" do
    guide = Guides.markup("components.md")
    assert guide =~ "<h1>\nComponent stories</h1>"
  end

  test "sandboxing guide" do
    guide = Guides.markup("sandboxing.md")
    assert guide =~ "<h1>\nSandboxing components</h1>"
  end

  test "icons guide" do
    guide = Guides.markup("icons.md")
    assert guide =~ "<h1>\nCustom Icons</h1>"
  end
end
