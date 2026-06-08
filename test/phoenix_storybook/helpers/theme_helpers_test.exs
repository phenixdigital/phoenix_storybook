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

  defmodule DataAttributeBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :data_attribute, "test-theme")
    end
  end

  defmodule DataAttributeNilBackend do
    def config(:themes_strategies, default) do
      Keyword.put(default, :data_attribute, nil)
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

  defmodule ThemesBackend do
    def config(:themes), do: [default: [name: "Default"], colorful: [name: "Colorful"]]
  end

  test "theme_sandbox_class returns nil when no sandbox strategy" do
    assert ThemeHelpers.theme_sandbox_class(SandboxNilBackend, :default) == nil
  end

  test "theme_sandbox_class prefixes theme when strategy exists" do
    assert ThemeHelpers.theme_sandbox_class(SandboxPrefixBackend, :default) == "sandbox-default"
  end

  test "theme_sandbox_data_attribute nil when no sandbox strategy" do
    assert ThemeHelpers.theme_sandbox_data_attribute(DataAttributeNilBackend, :default) == nil
  end

  test "theme_sandbox_data_attribute returns configured data attribute pair as tuple" do
    assert ThemeHelpers.theme_sandbox_data_attribute(DataAttributeBackend, :default) ==
             {:"data-test-theme", "default"}
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

  test "theme_from_param resolves configured themes" do
    assert ThemeHelpers.theme_from_param(ThemesBackend, "default") == :default
    assert ThemeHelpers.theme_from_param(ThemesBackend, :colorful) == :colorful
  end

  test "theme_from_param rejects unknown binary themes without interning atoms" do
    unknown_theme = "psb_unknown_#{System.unique_integer([:positive])}"

    assert_raise RuntimeError, ~r/unknown theme/, fn ->
      ThemeHelpers.theme_from_param(ThemesBackend, unknown_theme)
    end

    assert_raise ArgumentError, fn -> String.to_existing_atom(unknown_theme) end
  end
end
