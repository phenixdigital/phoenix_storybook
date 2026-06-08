defmodule PhoenixStorybook.Guides.GuidesTest do
  use ExUnit.Case, async: true

  defmodule Guides do
    use PhoenixStorybook.Guides.Macros
  end

  test "components guide" do
    guide = Guides.markup("components.md")
    assert guide =~ "<h1>Component stories</h1>"
  end

  test "sandboxing guide" do
    guide = Guides.markup("sandboxing.md")
    assert guide =~ "<h1>Sandboxing components</h1>"
  end

  test "icons guide" do
    guide = Guides.markup("icons.md")
    assert guide =~ "<h1>Custom Icons</h1>"
  end
end
