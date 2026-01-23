defmodule PhoenixStorybook.ThemeHelpersTest do
  use ExUnit.Case, async: true

  alias PhoenixStorybook.ThemeHelpers

  defmodule SandboxPrefixBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :sandbox_class, "sandbox")
    end
  end

  defmodule SandboxNilBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :sandbox_class, nil)
    end
  end

  defmodule AssignBinaryBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :assign, "theme")
    end
  end

  defmodule AssignAtomBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :assign, :theme)
    end
  end

  defmodule FunctionBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :function, {__MODULE__, :apply_theme})
    end

    def apply_theme(theme), do: {:ok, theme}
  end

  defmodule FunctionNilBackend do
    def config(:themes_strategies, default), do: default
  end

  test "theme_sandbox_class returns nil when no sandbox strategy" do
    assert ThemeHelpers.theme_sandbox_class(SandboxNilBackend, :default) == nil
  end

  test "theme_sandbox_class prefixes theme when strategy exists" do
    assert ThemeHelpers.theme_sandbox_class(SandboxPrefixBackend, :default) == "sandbox-default"
  end

  test "theme_assign returns nil when no assign strategy" do
    assert ThemeHelpers.theme_assign(SandboxNilBackend, :default) == nil
  end

  test "theme_assign converts binary key to atom" do
    assert ThemeHelpers.theme_assign(AssignBinaryBackend, :default) == {:theme, :default}
  end

  test "theme_assign keeps atom key" do
    assert ThemeHelpers.theme_assign(AssignAtomBackend, :default) == {:theme, :default}
  end

  test "call_theme_function returns nil when no function strategy" do
    assert ThemeHelpers.call_theme_function(FunctionNilBackend, :default) == nil
  end

  test "call_theme_function applies configured function" do
    assert ThemeHelpers.call_theme_function(FunctionBackend, :default) == {:ok, :default}
  end
end
