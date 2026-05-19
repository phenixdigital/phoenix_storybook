defmodule PhoenixStorybook.ThemeHelpers do
  @moduledoc false

  def theme_sandbox_class(backend_module, theme) do
    case theme_strategy(backend_module, :sandbox_class) do
      nil -> nil
      prefix -> "#{prefix}-#{theme}"
    end
  end

  def theme_assign(backend_module, theme) do
    case theme_strategy(backend_module, :assign) do
      nil -> nil
      assign_key when is_binary(assign_key) -> {String.to_atom(assign_key), theme}
      assign_key -> {assign_key, theme}
    end
  end

  def theme_from_param(_backend_module, theme) when theme in [nil, ""], do: nil
  def theme_from_param(_backend_module, theme) when is_atom(theme), do: theme

  def theme_from_param(backend_module, theme) when is_binary(theme) do
    case backend_module.config(:themes) do
      nil ->
        raise(RuntimeError, "unknown theme: #{theme}")

      themes ->
        Enum.find_value(themes, fn {theme_id, _label} ->
          if to_string(theme_id) == theme, do: theme_id
        end) || raise(RuntimeError, "unknown theme: #{theme}")
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
