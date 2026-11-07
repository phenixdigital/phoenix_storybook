# Screen sizes

The Variations tab of a component story has a **Screen size** select. Pick a size and the story's
variations render in an iframe that is exactly that wide, so you can check how a component responds
on a phone, a tablet or a desktop without resizing your browser.

## Why an iframe?

CSS media queries (`@media (min-width: ...)`, Tailwind's `sm:` / `md:` / `lg:` variants...) only
respond to the width of the **viewport**, not to the width of the element around your component.
Rendering a component in a narrow `div` would not trigger them.

The preview is an iframe whose width _is_ the target width. Inside it, media queries see that width
as the viewport, so the preview is faithful with any CSS framework, and no class is rewritten.

All the variations of the story render in a single iframe, so selecting a screen size costs one
extra page load, whatever the number of variations.

## Default presets

The presets are the ones of [Storybook JS](https://storybook.js.org/docs/essentials/viewport):

| Preset         | Width  |
| -------------- | ------ |
| Small mobile   | 320px  |
| Large mobile   | 414px  |
| Tablet         | 834px  |
| Desktop        | 1280px |

The preview is never scaled down: when it is wider than the pane, the pane scrolls horizontally.
Its height follows its content.

You can also drag the preview's bottom right corner to any width: the select then shows **Custom**
and the width is stored in the URL.

## Custom presets

Set the `viewports:` option in your storybook backend to use your own presets. It is a keyword list
of `preset_key: {label, width_px}`. For instance, with Tailwind's default breakpoints:

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhoenixStorybook,
    # ...
    viewports: [
      sm: {"sm", 640},
      md: {"md", 768},
      lg: {"lg", 1024},
      xl: {"xl", 1280},
      "2xl": {"2xl", 1536}
    ]
end
```

Set `viewports: false` to remove the Screen size select.

## URL parameters

The selection lives in the URL, so a preview can be shared:

- `viewport=tablet` selects a preset by its key, `viewport=419` a custom width in px.
- `variation_id=hello` shows only that variation, `group_id=group` a whole variation group, and
  `group_id=group&variation_id=hello` one variation of a group. The **Variation** select next to
  the Screen size select sets them.

An unknown preset, a width that is not a positive integer, or an unknown variation or group raises
an error.

The preview iframe itself is served by `/iframe/<story>?variations=all`, which accepts the same
`group_id` and `variation_id` parameters.

## Layout

Each variation renders in the same container as in the regular Variations tab, following the
same rules, so a story looks the same with **None** and with a screen size, only narrower:

- A `:div` container is centred, with a small padding. A container `class` replaces that default
  layout class (the sandbox class is kept), and any other option, such as `"data-foo": "bar"`,
  becomes an HTML attribute and keeps the default layout.
- An `:iframe` container renders as a plain `div` inside the preview, since the preview iframe
  already isolates it. Its `style` replaces the default centred style, as inside its own iframe
  in the Variations tab. Its other options are attributes of that per-variation iframe, so they
  don't apply here.

For instance, for a navigation bar or a page layout that should span the whole width:

```elixir
# storybook/navbar.story.exs
defmodule Storybook.Navbar do
  use PhoenixStorybook.Story, :component
  def container, do: {:div, class: "p-0"}
end
```
