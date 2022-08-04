# PhxLiveStorybook

![github](https://github.com/phenixdigital/phx_live_storybook/actions/workflows/elixir.yml/badge.svg)
[![codecov](https://codecov.io/gh/phenixdigital/phx_live_storybook/branch/main/graph/badge.svg)](https://codecov.io/gh/phenixdigital/phx_live_storybook)
[![GitHub release](https://img.shields.io/github/v/release/phenixdigital/phx_live_storybook.svg)](https://github.com/phenixdigital/phx_live_storybook/releases/)

📚 [Online Documentation](https://hexdocs.pm/phx_live_storybook) &nbsp; - &nbsp; 🔎 [Online Demo](http://phx-live-storybook-sample.fly.dev/storybook)

<!-- MDOC !-->

PhxLiveStorybook provides a [_storybook-like_](https://storybook.js.org) UI interface for your Phoenix LiveView components.

- Explore all your components, and showcase them with different variations.
- Browse your components documentation, with their supported attributes (_soon_).
- Learn how components behave by using an interactive playground (_soon_).

![screenshot](https://github.com/phenixdigital/phx_live_storybook/raw/main/screenshot.png)

## How does it work?

PhxLiveStorybook is mounted in your application router and serves its UI at the mounting point of your choice.

It performs an automatic discovery of your storybook content under a specified folder (`:content_path`) and then automatically generate storybook navigation sidebar. Every module detected in your content folder, will be loaded and identified as a storybook entry.

Three kind of entries are supported:

- `component` to describe your stateless function components.
- `live_component` to describe your live components.
- `page` to write & document UI guidelines, or whatever content you want.

Almost everything, from sidebar rendering to component preview, is performed at compilation time.

## Installation

To start using `PhxLiveStorybook` in your phoenix application you will need to follow these steps:

1. Add the `phx_live_storybook` dependency
2. Create your storybook backend module
3. Add storybook access in your router
4. Make your components assets available
5. Configure your storybook
6. Create some content.

### 1. Add the `phx_live_storybook` dependency

Add the following to your mix.exs and run mix deps.get:

```elixir
def deps do
  [
    {:phx_live_storybook, "~> 0.2.0"}
  ]
end
```

### 2. Create your storybook backend module

Create a new module under your application lib folder.

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhxLiveStorybook, otp_app: :my_app
end
```

This backend module ensures the storybook gets recompiled as soon as you update your storybook content (see section 5.)

### 3. Add storybook access in your router

Once installed, update your router's configuration to forward requests to a `PhxLiveStorybook` with a unique name of your choosing:

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import PhxLiveStorybook.Router

...

scope "/" do
  pipe_through :browser
  live_storybook "/storybook",
    otp_app: :my_app,
    backend_module: MyAppWeb.Storybook
end
```

### 4. Make your components assets available

Build a new css bundle dedicated to your live_view components: this bundle will be used both by your app and the storybook.

In this README, we use `assets/css/my_components.css` as an example.

If your components require any hooks or custom uploaders, declare them as such in a new JS bundle:

```javascript
// assets/js/my_components.js

import * as Hooks from "./hooks";
import * as Uploaders from "./uploaders";

(function () {
  window.storybook = { Hooks, Uploaders };
})();
```

### 5. Configure your storybook

In your configuration files, add the following.

```elixir
# config/config.exs

config :my_app, MyAppWeb.Storybook,
  content_path: Path.expand("../storybook", __DIR__),
  css_path: "/assets/my_components.css",
  js_path: "/assets/my_components.js"
```

### 6. Create some content.

Then you can start creating some content for your storybook. Storybook can contain 3 different kind of _entries_:

- **component entries**: to document and showcase your components.
- **pages**: to publish some UI guidelines, framework or whatever with regular HTML content.
- **samples**: to show how your components can be used and mixed togethers in real UI pages.

_As of `0.3.0`, only component and page entries are available._

Entries are described as Elixir scripts (`.exs`), created under your `:content_path` folder. Feel free to organize them in sub-folders, as the hierarchy will be respected in your storybook sidebar.

Here is an example of a stateless (function) component entry:

```elixir
# storybook/components/button.exs

defmodule MyAppWeb.Storybook.Components.Button do
  alias MyAppWeb.Components.Button

  # :live_component or :page are also available
  use PhxLiveStorybook.Entry, :component

  def function, do: &Button.button/1
  def description, do: "A simple generic button."

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          label: "A button"
        }
      },
      %Variation{
        id: :green_button,
        attributes: %{
          :label => "Still a button",
          :"bg-color" => "bg-green-600",
          :"hover-bg-color" => "bg-green-700"
        }
      }
    ]
  end
end
```

### Configuration

All config settings, only the `:content_path` key is mandatory.

```elixir
# config/config.exs
config :my_app, MyAppWeb.Storybook,

  # Path to your storybook entries (required).
  content_path: Path.expand("../storybook", __DIR__),

  # Path to your components stylesheet.
  css_path: "/assets/my_components.css",

  # Path to your JS asset, which will be loaded just before PhxLiveStorybook's own
  # JS. It's mainly intended to define your own LiveView Hooks in `window.storybook.Hooks`.
  js_path: "/assets/my_components.js",

  # Custom storybook title. Default is "Live Storybook".
  title: "My Live Storybook",

  # Folder settings.
  # Each folder is designated by its relative path from the storybook mounting point.
  # For each folder you can:
  # - make it open by defaut in the sidebar, with `open: true`.
  # - give it a custom name in the sidebar
  # - give it a custom icon in the sidebar, with a FontAwesome 6+ CSS class.
  folders: [
    "/": [icon: "fas fa-banana"],
    "/components": [icon: "far fa-toolbox", open: true],
    "components/live": [icon: "fal fa-bolt", name: "Live!!!"]
  ]
```

<!-- MDOC !-->

### License

MIT License. Copyright (c) 2022 Christian Blavier
