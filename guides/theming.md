# Theming components

## Theming Strategies

The storybook gives you different possibilities to apply a theme to your components. These
possibilities are named _strategies_.

The following strategies are available:

1. _sandbox class_: set your theme as a CSS class, on the sandbox container, with a custom prefix
2. _data attribute_ (`data_attribute`): set your theme on the sandbox container as a `data-*` attribute.
3. _assign_: pass the theme as an assign to your components, with a custom key.
4. _function_: call a custom module/function along with the current theme.

Here is how you can use these strategies. In your `storybook.ex`:

```elixir
use PhoenixStorybook,
  themes_strategies: [
    sandbox_class: "prefix", # will set a class prefixed by `prefix-` on the sandbox container
    data_attribute: "name", # will set data-name="theme" on the sandbox container
    assign: :theme,
    function: {MyApp.ThemeHelper, :register_theme}
  ]
```

If the `themes_strategies` key is undefined, the default `sandbox_class: "theme"` strategy is applied.

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
because the Hook is running under the same pid than the LiveView).

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

# Theming the storybook UI

Everything above themes **your components** inside the sandbox. The storybook
**chrome itself** (sidebar, header, playground, docs…) has its own theme, built
from a small set of shadcn-style semantic tokens exposed as CSS custom
properties (`--psb-color-*`, plus a `--psb-radius` scale) and `psb:`-prefixed
Tailwind utilities. You can recolor **and** reskin it to match your brand.

The theme file is built by Tailwind and served like your other assets, then
imported by the storybook **unlayered**, after its own stylesheet. Because it is
unlayered, your rules win over both the shipped token defaults and the `psb:*`
utilities baked into the markup — in light and dark mode. This lets you:

- **recolor** by overriding tokens (`--psb-color-*`, `--psb-radius`), and
- **reskin** by overriding structural rules (borders, spacing, shadows…).

## Two stylesheets, two jobs

`mix phx.gen.storybook` scaffolds two separate CSS files, and it is easy to mix
them up. They paint different surfaces and never overlap:

| | `storybook.css` (`css_path`) | `storybook_theme.css` (`theme_path`) |
| --- | --- | --- |
| Styles | **your components**, in the sandbox | **the storybook chrome** (sidebar, header, playground, docs…) |
| Companion to | your app's `app.css` | — (a UI skin, new to the storybook) |
| Tailwind prefix | none — your app's own utilities (`bg-blue-500`) | `psb:` — the storybook's engine (`psb:bg-blue-500`) |
| Imported | with `layer(app)` | **unlayered**, after everything else |
| If omitted | your components render unstyled | chrome uses its shipped violet/neutral theme |

The rule of thumb: if you are styling something a story renders, it goes in
`storybook.css`. If you are styling the storybook interface *around* those
stories, it goes in `storybook_theme.css`.

`storybook.css` carries whatever your components need — PhoenixStorybook loads
it **instead of** your `app.css`, so any `@plugin`, `@custom-variant`, font, or
`@source` you rely on must be mirrored there:

```css
/* assets/css/storybook.css — themes your components */
@import "tailwindcss" source(none);
@source "../../storybook";

.my-app-sandbox h1 {
  font-family: "Inter", sans-serif;
}
```

`storybook_theme.css` only overrides the chrome's tokens and rules — no
`@source`, no component utilities:

```css
/* assets/css/storybook_theme.css — themes the storybook UI */
:root {
  --psb-color-primary: #0ea5e9;
}
```

The rest of this section is about `storybook_theme.css`. For `storybook.css` and
the sandbox, see the [sandboxing guide](sandboxing.md).

## The theme file

`mix phx.gen.storybook` scaffolds an annotated `assets/css/storybook_theme.css`
for you (also available at
[`priv/templates/phx.gen.storybook/storybook_theme.css`](https://github.com/phenixdigital/phoenix_storybook/blob/main/priv/templates/phx.gen.storybook/storybook_theme.css)).
Keep the tokens you want to change, and delete the rest:

```css
/* assets/css/storybook_theme.css */
:root {
  --psb-color-primary: #0ea5e9;
  --psb-radius: 0.375rem;
}

.psb\:dark {
  --psb-color-primary: #38bdf8;
}
```

Notes:

- Override the **prefixed** names (`--psb-color-*`), not the unprefixed
  `--color-*` names.
- Values can be raw (`#0ea5e9`, `oklch(...)`) or reference the bundled palette
  (`var(--psb-color-sky-500)`).
- The dark-mode block is keyed on `.psb\:dark` (note the escaped colon).

## Reskinning with plain rules or `@apply`

Since the file is unlayered, a plain rule overrides the utilities in the markup.
For example, to drop the border around the playground component preview:

```css
:has(> [id$="-playground-preview"]) {
  border-width: 0;
}
```

To reuse the storybook's own `psb:*` utilities via `@apply`, reference the
storybook's Tailwind setup first — this emits no CSS, it only makes the
utilities and `--psb-color-*` theme available to the compiler:

```css
@reference "../../deps/phoenix_storybook/priv/phoenix_storybook.css";

:has(> [id$="-playground-preview"]) {
  @apply psb:border-0 psb:shadow-none;
}
```

> #### Internal selectors {: .warning}
>
> Structural rules target PhoenixStorybook's internal `psb`-prefixed markup,
> which is not a stable API and may change between releases. Token overrides are
> the stable surface; reach for structural rules only when a token cannot express
> what you need.

## Wiring it up

The theme file goes through your asset build, exactly like `css_path`. The
generator sets `theme_path` in your backend and prints the build steps to add
(a `storybook_theme` Tailwind profile, a dev watcher, and `assets.build` /
`assets.deploy` alias entries):

```elixir
use PhoenixStorybook,
  otp_app: :my_app,
  # remote path, served from priv/static — not a local file-system path
  theme_path: "/assets/css/storybook_theme.css"
```

The built file's fingerprint is tracked as an external resource, so rebuilding it
busts the cache; if `theme_path` points at a file that has not been built yet,
the storybook logs a warning and falls back to its shipped defaults.
