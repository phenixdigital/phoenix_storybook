# Sandboxing components

In `PhoenixStorybook` your components live within the storybook, so they share some context with
the storybook: **styling** and **scripts**.

While the original Storybook for React only [relies on iframes](https://storybook.js.org/docs/react/configure/story-rendering),
we find them quite slow and don't want them to be the default choice.

This guide will explain:

- what JS context do your components share with the storybook?
- how is the storybook styled to prevent most styling clashes?
- how you should provide the style of your components with scoped styles.
- how to, as a last resort, enable iframe rendering.

## What JS context do your components share with the storybook?

`PhoenixStorybook` runs with Phoenix LiveView and therefore requires its `LiveSocket`. This
LiveSocket is the same used by your components: you just need to inject it with your own `Hooks`,
`Params` and `Uploaders`.

To do so, create a JS file that will declare your `Hooks`, `Params` and `Uploaders` and set them in
`window.storybook`. This script will be loaded immediately before the storybook's script.

> :information_source: If you used `mix phx.gen.storybook` this file has already been created for you.

```javascript
// assets/js/storybook.js
import * as Hooks from "./hooks";
import * as Params from "./params";
import * as Uploaders from "./uploaders";
(function () {
  window.storybook = { Hooks, Params, Uploaders };
})();
```

Then set the `js_path: "/assets/storybook.js"` option to the storybook within your `storybook.ex`
file. This is a remote path (not a local file-system path) which means this file should be served
by your own application endpoint with the given path.

If you are using ESM-style imports, you can set the `js_script_type: "module"`" option as well.

You can also use this script to inject whatever content you want into document `HEAD`, such as
external scripts.

The `Params` will be available in page stories as `connect_params` assign.
There is currently no way to access them in component or live component stories.

## How is the storybook styled?

`PhoenixStorybook` is using [TailwindCSS 4.x](https://tailwindcss.com) with
[preflight](https://tailwindcss.com/docs/preflight) (which means all default HTML styles from your
browser are removed) and a [custom prefix](https://tailwindcss.com/docs/configuration#prefix):
`psb:` (which means that instead of using `bg-blue-400` the storybook uses `psb:bg-blue-400`).

Only elements with the `.psb` class are preflighted, in order to let your component styling as-is.

So unless your components use `psb` or `psb:` prefixed classes there should be no styling leak from
the storybook to you components.

## How should you provide the style of your components?

You need to inject your component's stylesheets into the storybook. Set the
`css_path: "/assets/storybook.css"` option in `storybook.ex`. This is a remote path (not a local
file-system path) which means this file should be served by your own application endpoint with the
given path.

Please note that your stylesheet is loaded within the `app` CSS layer. Layer are applied with the following order, giving your stylesheet priority over the storybook 
styles.
```css
@layer reset, theme, app, utilities;
```

The previous part was about storybook styles not leaking into your components. This part is
about the opposite: don't accidentally mess up Storybook styling with your styles.

All containers rendering your components in the storybook (`stories`, `playground`, `pages` ...)
carry the `.psb-sandbox` CSS class and a **custom sandboxing class of your choice**.

You can leverage this to scope your styles with this class. Here is how you can do it with
`TailwindCSS` (instructions provided for Tailwind 4.x):

- configure `phoenix_storybook` with a custom `sandbox_class`:

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhoenixStorybook,
    ...
    sandbox_class: "my-app-sandbox",
```

- nest your custom styles under your sandbox CSS class.

```css
/* assets/css/storybook.css */
@import "tailwindcss";

.my-app-sandbox {
  * {
    font-family: "MyComponentsFont";
    @apply text-slate-600;
  }

  h1 {
    @apply text-2xl font-bold text-slate-700 mt-2 mb-6;
  }

  h2 {
    @apply text-xl font-bold text-slate-700 mt-2 mb-4;
  }
}
```

- set your sandbox CSS class to the body element of your main application.

```html
<!-- lib/my_app/templates/layout/root.html.heex -->

<html>
  <body class="my-app-sandbox">
    <!-- ... -->
  </body>
</html>
```

## Enabling iframe rendering

As a last resort, if for whatever reason you cannot make your component live within the storybook,
it is possible to enable iframe rendering, component per component.

This could be required e.g. if you need to bind listeners on `document` or when
you want to make sure responsive css works as expected.

Just add the `iframe` option to it.

```elixir
# storybook/components/button.exs
defmodule MyAppWeb.Storybook.Components.Button do
 alias MyAppWeb.Components.Button
 use PhoenixStorybook.Story, :component

 def function, do: &Button.button/1
 def container, do: :iframe

 # ...
end
```
