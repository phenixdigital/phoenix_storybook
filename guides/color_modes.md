# Color modes

The storybook supports three color modes: _dark_, _light_ and _system_.

- The Storybook's styling adapts based on the selected color mode.
- Your components are wrapped in a `<div>` with a custom dark class.

The different modes are handled as follows:

- `dark`: the `dark` class (or custom dark class) is applied to your component's sandbox
- `light`: no class is applied
- `system`: The `dark` class is added if your system prefers dark mode (as determined by the `prefers-color-scheme` media query).

## Setup

To enable color mode support, you need to configure it in your Storybook setup:

```elixir
use PhoenixStorybook,
  # ...
  color_mode: true
```

This configuration adds a color theme picker to the Storybook header, allowing you to render the Storybook with the selected mode.

## Component rendering

When your components are rendered in Storybook, they are wrapped in a sandbox element (read [sandboxing guide](sandboxing.md)).

- If the current color mode is dark (or system mode with dark preference), the sandbox will have a `dark` CSS class.
- In light mode, no class is applied.

You can customize the default dark class by specifying it in your configuration:

```elixir
use PhoenixStorybook,
  # ...
  color_mode_sandbox_dark_class: "my-dark",
```

## Tailwind setup

If you use Tailwind 4.x for your components, update your main CSS file as follows:

```css
@custom-variant dark (&:where(.dark, .dark *));
```

In your application, ensure that the dark mode class is applied to your DOM element, particularly on or under your sandbox element:

```html
<html class="storybook-demo-sandbox dark">
  ...
</html>
```
