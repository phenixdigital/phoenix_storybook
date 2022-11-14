# Theming components

## Theming Strategies

The storybook gives you different possibilities to apply a theme to your components. These
possibilities are named _strategies_.

The following strategies are available:

1. _sandbox class_: set your theme as a CSS class, on the sandbox container, with a custom prefix
2. _assign_: pass the theme as an assign to your components, with a custom key.
3. _function_: call a custom module/function along with the current theme.

Here is how you can use these strategies. In your `storybook.ex`:

```elixir
use PhxLiveStorybook,
  themes_strategies: [
    sandbox_class: "prefix", # will set a class prefixed by `prefix-` on the sandbox container
    assign: :theme,
    function: {MyApp.ThemeHelper, :register_theme}
  ]
```

If the `theme_strategies` key is undefined, the default `sandbox_class: "theme"` strategy is applied.

## CSS theming

By default, the storybook is applying a `theme-*` CSS class to your components/page containers and
you should do as well to your application HTML body element.

It will allow you to style raw HTML elements

```css
body.theme-colorful {
  font-family: // ...
}

.theme-colorful h1 {
  font-family: // ...
  font-size: // ...
}
```

## Using a Registry

This chapter explain how you can leverage on a `Registry` with the _function_ theming strategy.

An effective way to store the current theme setting so that it can be available to all your
components, but still have different values for different (concurrent) users is to associate it to
the current LiveView pid.

`Registry` is a native Elixir module that handles decentralized storage, linked to specific
processes. We will leverage on this to associate a theme to the current LiveView pid.

First start a `Registry` from your `Application` module.

```elixir
defmodule PhenixStorybook.Application do
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: ThemeRegistry}
    ]
  end
end
```

Then create a **LiveView Hook** that will fetch the theme from wherever it is relevant for your
application: database, user session, URL params... and store it in the `Registry` (it's working
because the Hook is running under the same pid than the Liveview).

```elixir
defmodule ThemeHook do
  def on_mount(:default, params, _session, socket) do
    theme = current_user_theme(socket, params)
    Registry.register(ThemeRegistry, :theme, theme)
    {:cont, socket}
  end
end
```

Mount the hook in your `router`.

```elixir
defmodule Router do
  live_session :default, on_mount: [ThemeHook] do
    scope "/" do
      # ...
    end
  end
end
```

Write a helper module, to be used from your components to fetch the current theme from the
`Registry` and merge it in the component's assigns.

```elixir
defmodule ThemeHelpers do
  def set_theme(assigns) do
    pid_and_themes = Registry.lookup(ThemeRegistry, :theme)

    case find_by_pid(pid_and_themes, self()) do
      {_pid, theme} -> Map.put_new(assigns, :theme, theme)
      _ -> raise("theme not found in registry")
    end
  end

  defp find_by_pid(pid_and_themes, current_pid) do
    Enum.find(pid_and_themes, fn {pid, _} -> pid == current_pid end)
  end
end
```
