# Sandboxing components

In `PhxLiveStorybook` your components live within the storybook, so they share
some context with the storybook: **styling** and **scripts**.

While the original Storybook for React only [relies on iframes](https://storybook.js.org/docs/react/configure/story-rendering),
we found them quite slow and don't want them to be the default choice.

This guide will explain:

- what JS context do your components share with the storybook?
- how is the storybook styled, to prevent most styling clashes?
- how should you provide the style of your components with scoped styles?
- how to, as a last resort, enable iframe rendering?

## 1. What JS context do your components share with the storybook?

`PhxLiveStorybook` runs with Phoenix LiveView and therefore requires its `LiveSocket`.
This LiveSocket is the same used by your components: you just need to inject it with your
own `Hooks` and `Uploaders`.

To do so, create a JS file that will declare your `Hooks` and `Uploaders` and set them in
`window.storybook`. This script will be loaded immediately before the storybook's script.

```javascript
// assets/js/my_components.js
import * as Hooks from "./hooks";
import * as Uploaders from "./uploaders";
(function () {
  window.storybook = { Hooks, Uploaders };
})();
```

Then set the `js_path: "/assets/js/components.js"` option to the storybook within your `config.exs`
file.

You can also use this script to inject whatever content you want into document `HEAD`, such as
external scripts.

## 2. How is the storybook styled?

`PhxLiveStorybook` is using [TailwindCSS](https://tailwindcss.com) with
[preflight](https://tailwindcss.com/docs/preflight) (which means all default HTML styles from your
browser are removed) and a [custom prefix](https://tailwindcss.com/docs/configuration#prefix):
`lsb-` (which means that instead of using `bg-blue-400` the storybook uses `lsb-bg-blue-400`).

Only elements with the `.lsb` class are preflighted, in order to let your component styling as-is.

So unless your components use `lsb` or `lsb-` prefixed classes there should be no styling leak from
the storybook to you components.

## 3. How should you provide the style of your components?

You need to inject your component's stylesheets into the storybook. Just (like for JS), set the
`css_path: "/assets/css/components.css"` option in `config.exs`.

The previous part (2.) was about storybook styles not leaking into your components. This part is
about the opposite: don't accidentally mess up Storybook styling with your styles.

All containers rendering your components in the storybook (`stories`, `playground`, `pages` ...)
have the `.lsb-sandbox` CSS class.

You can leverage this to scope your styles with this class. Here is how you can do it with `TailwindCSS`:

- use Tailwind [important selector strategy](https://tailwindcss.com/docs/configuration#selector-strategy)
  with this class. It will prefix all your tailwind classes with `.lsb-sandbox` increasing their
  specificity, hence their priority.

```javascript
// assets/tailwind.config.js
module.exports = {
  // ...
  important: ".lsb-sandbox",
};
```

- nest your custom styles under Tailwind `@layer utilities`. This way, your styling will also
  benefit from `.lsb-sandbox` scoping.

```css
/* assets/css/components.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer utilities {
  /* this style will be generated as .lsb-sandbox * { ... } */
  * {
    font-family: "MyComponentsFont";
    @apply text-slate-600;
  }

  /* this style will be generated as .lsb-sandbox h1 { ... } */
  h1 {
    @apply text-2xl font-bold text-slate-700 mt-2 mb-6;
  }

  /* this style will be generated as .lsb-sandbox h2 { ... } */
  h2 {
    @apply text-xl font-bold text-slate-700 mt-2 mb-4;
  }
}
```

## 4. Enabling iframe rendering

As a last resort, if for whatever reason you cannot make your component live within the storybook
(an example would be that your component needs to bind listeners on `document`), it is possible to
enable iframe rendering, component per component.

Just add the `iframe` option to it.

```elixir
# storybook/components/button.exs
defmodule MyAppWeb.Storybook.Components.Button do
 alias MyAppWeb.Components.Button
 use PhxLiveStorybook.Story, :component

 def function, do: &Button.button/1
 def container, do: :iframe

 # ...
end
```
