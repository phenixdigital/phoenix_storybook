defmodule PhoenixStorybook.ThemeHelpers do
  @moduledoc false

  def theme_sandbox_class(backend_module, theme) do
    case theme_strategy(backend_module, :sandbox_class) do
      nil -> nil
      prefix -> "#{prefix}-#{theme}"
    end
  end

  def theme_sandbox_data_attribute(backend_module, theme) do
    case theme_strategy(backend_module, :data_attribute) do
      nil ->
        nil

      attribute_name when is_binary(attribute_name) ->
        {String.to_atom("data-#{attribute_name}"), "#{theme}"}

      attribute_name when is_atom(attribute_name) ->
        {String.to_atom("data-#{Atom.to_string(attribute_name)}"), "#{theme}"}

      attribute_name ->
        raise ArgumentError,
              "expected :data_attribute theme strategy to be a binary or atom, got: #{inspect(attribute_name)}"
    end
  end

  def theme_assign(backend_module, theme) do
    case theme_strategy(backend_module, :assign) do
      nil -> nil
      assign_key when is_binary(assign_key) -> {String.to_atom(assign_key), theme}
      assign_key -> {assign_key, theme}
    end
  end

  def call_theme_function(backend_module, theme) do
    case theme_strategy(backend_module, :function) do
      nil -> nil
      {module, fun} -> apply(module, fun, [theme])
    end
  end

  def theme_strategy(backend_module, strategy) do
    backend_module.config(:themes_strategies, sandbox_class: "theme")
    |> Keyword.get(strategy)
  end
end
