# Color modes

The storybook can support color modes: _dark_, _light_ and _system_.

- The storybook style itself is styled based on the selected color mode
- Your components will be wrapped in a div with a custom dark class.

The different modes are handled as such:

- when `dark`, the `dark` class (or custom dark class) is added on your components sandbox
- when `light`, no class is set
- when `system`, it will add the `dark` class if your system prefers dark (cf. `prefers-color-scheme`)

## Setup

First you need enable `color_mode` support.

```elixir
use PhoenixStorybook,
  # ...
  color_mode: true
```

This will add a new color theme picker in the storybook header. At this time you should be able
to render the storybook with the new mode.

## Component rendering

Whenever a component of yours is rendered in the storybook, it's wrapped under a sandbox element (read [sandboxing guide](sandboxing.md))

If the current color_mode is dark (or system with your system being dark), then the sandbox will carry a `dark` css class. When in light mode, no class is set.

You can customize the default dark class:

```elixir
use PhoenixStorybook,
  # ...
  color_mode_sandbox_dark_class: "my-dark",
```

## Tailwind setup

If you use Tailwind for your own components, then update your `tailwind.config.js` accordingly.

```js
module.exports = {
  // ...
  darkMode: "selector",
};
```

A custom dark class can be used like this:

```js
module.exports = {
  // ...
  darkMode: ["selector", ".my-dark"],
};
```

In your own application, when setting the dark mode class to your DOM, make sure it is added on
(or under) your sandbox/important element.

```html
<html class="storybook-demo-sandbox dark">
  ...
</html>
```
