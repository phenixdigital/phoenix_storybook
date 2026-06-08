# Manual setup

To start using `PhoenixStorybook` in your Phoenix application you will need to follow these steps:

1. Add the `phoenix_storybook` dependency
2. Create your storybook backend module
3. Add storybook access to your router
4. Make your components' assets available
5. Update your Docker image
6. Create some content

## 1. Add the `phoenix_storybook` dependency

Add the following to your mix.exs and run mix deps.get:

```elixir
def deps do
  [
    {:phoenix_storybook, "~> 1.1.0"}
  ]
end
```

## 2. Create your storybook backend module

Create a new module under your application lib folder:

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :my_app,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/css/storybook.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "my-app"
end
```

## 3. Add storybook access to your router

Once installed, update your router's configuration to forward requests to a `PhoenixStorybook`
with a unique name of your choice:

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import PhoenixStorybook.Router
...
scope "/" do
  storybook_assets()
end

scope "/", MyAppWeb do
  pipe_through :browser
  ...
  live_storybook "/storybook", backend_module: MyAppWeb.Storybook
end
```

## 4. Make your components' assets available

PhoenixStorybook loads the `css_path` / `js_path` bundles you configured above — **not** your
application's `app.css` / `app.js`. You need to build and serve those two bundles. The steps below
assume a default Phoenix 1.8 app (Tailwind v4 + esbuild); adjust the paths if your asset pipeline
differs. Sub-steps b, d and e are Tailwind-specific — on another pipeline, substitute your own CSS
build, watcher, and deploy steps. This is exactly what `mix phx.gen.storybook` walks you through.

### a. JS bundle

This script is loaded immediately before PhoenixStorybook's own JS. Use it to declare your LiveView
`Hooks`, `Params` and `Uploaders` on `window.storybook` — keep only the ones your components need:

```javascript
// assets/js/storybook.js

import * as Hooks from "./hooks";
import * as Params from "./params";
import * as Uploaders from "./uploaders";

(function () {
  window.storybook = { Hooks, Params, Uploaders };
})();
```

Add it as a new entry point to your existing esbuild profile in `config/config.exs`:

```elixir
config :esbuild,
  my_app: [
    args:
      ~w(js/app.js js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]
```

### b. CSS bundle

Create `assets/css/storybook.css`. Because PhoenixStorybook loads this file instead of your
`app.css`, you must mirror any `@plugin`, theme, custom variant or font your components rely on —
otherwise they render unstyled:

```css
/* assets/css/storybook.css */
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/my_app_web";
@source "../../storybook";

/* Mirror here any @plugin / @custom-variant / theme blocks from your app.css */
```

Add a `storybook` Tailwind build profile in `config/config.exs`:

```elixir
config :tailwind,
  my_app: [
    ...
  ],
  storybook: [
    args: ~w(
      --input=assets/css/storybook.css
      --output=priv/static/assets/css/storybook.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
```

### c. Scope your styles to the sandbox

All storybook containers carry your `sandbox_class`. Add it to your application layout body, and
nest your component styling under it so your app and the storybook stay in sync:

```heex
<!-- lib/my_app_web/components/layouts/root.html.heex -->
<body class="my-app">
```

Optionally, nest your own scoped component styles under that class in `assets/css/storybook.css`.
Global `@plugin` / `@custom-variant` / theme directives (e.g. daisyUI) must stay at the top level —
only your bespoke component CSS goes under the sandbox class:

```css
.my-app {
  /* your custom component styling, e.g. */
  h1 {
    @apply text-2xl font-bold;
  }
}
```

ℹ️ Learn more on this topic in the [sandboxing guide](sandboxing.md).

### d. Dev watcher & live reload

In `config/dev.exs`, add a watcher so the storybook CSS rebuilds on change, and a live-reload
pattern for your stories:

```elixir
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    ...
    storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ...
      ~r"storybook/.*\.exs$"
    ]
  ]
```

### e. Formatter & build aliases

Add your stories to `.formatter.exs` (importing `:phoenix_storybook` keeps the storybook DSL paren-free):

```elixir
[
  import_deps: [..., :phoenix_storybook],
  inputs: [
    ...
    "storybook/**/*.exs"
  ]
]
```

And make sure the storybook bundle is built with your other assets in `mix.exs`:

```elixir
defp aliases do
  [
    ...,
    "assets.build": [
      ...
      "tailwind storybook"
    ],
    "assets.deploy": [
      ...
      "tailwind storybook --minify",
      "phx.digest"
    ]
  ]
end
```

## 5. Update your Docker image

If you are deploying your app with Docker, then you need to copy the storybook content into your
Docker image.

Add this to your `Dockerfile`:

```docker
COPY storybook storybook
```

## 6. Create some content

Then you can start creating some content for your storybook. Storybook can contain different kinds
of _stories_:

- **component stories**: to document and showcase your components across different variations.
- **pages**: to publish some UI guidelines, framework with regular HTML content.
- **examples**: to show how your components can be used and mixed in real UI pages.

Stories are described as Elixir scripts (`.story.exs`) created under your `:content_path` folder.
Feel free to organize them in sub-folders, as the hierarchy will be respected in your storybook
sidebar.

Here is an example of a stateless (function) component story:

```elixir
# storybook/components/button.story.exs
defmodule MyAppWeb.Storybook.Components.Button do
  alias MyAppWeb.Components.Button

  # :live_component or :page are also available
  use PhoenixStorybook.Story, :component

  def function, do: &Button.button/1

  def variations do [
    %Variation{
      id: :default,
      attributes: %{
        label: "A button"
      }
    },
    %Variation{
      id: :green_button,
      attributes: %{
        label: "Still a button",
        color: :green
      }
    }
  ]
  end
end
```
