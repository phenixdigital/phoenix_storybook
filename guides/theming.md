# Theming components

## 1. The problem

The storybook allows you to apply different themes to your components. The selected theme is merged into the components assigns, which can then use
it to apply matching styling rules.

While this is working great in the storybook, **you probably don't want to pass
in your application code the same theme assign to all your components.**

## 2. Store the theme in a Registry

An effective way to store the current theme setting so that it can be available
to all your components, but still have different values for different (concurrent) users is to associate it to the current LiveView pid.

`Registry` is a native Elixir module that handles decentralized storage, linked to specific processes. We will leverage on this to associate a theme to the current LiveView pid.

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

Then create a **LiveView Hook** that will fetch the theme from wherever it is relevant for your application: database, user session, URL params... and store it in the `Registry` (it's working because the Hook is running under the same pid than the Liveview).

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

## 3. Fetch the theme from the Registry

Write a helper module, to be used from your components to fetch the current theme from the `Registry` and merge it in the component's assigns.

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

## 4. CSS theming

The storybook is applying a `theme-*` CSS class to your components/page containers and you should do as well to your application HTML body element.

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
