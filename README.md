# PhxLiveStorybook

![github](https://github.com/phenixdigital/phx_live_storybook/actions/workflows/elixir.yml/badge.svg)
[![codecov](https://codecov.io/gh/phenixdigital/phx_live_storybook/branch/main/graph/badge.svg)](https://codecov.io/gh/phenixdigital/phx_live_storybook)
[![GitHub release](https://img.shields.io/github/v/release/phenixdigital/phx_live_storybook.svg)](https://github.com/phenixdigital/phx_live_storybook/releases/)

📚 [Documentation](https://hexdocs.pm/phx_live_storybook)
&nbsp; - &nbsp;
🔎 [Demo](http://phx-live-storybook-sample.fly.dev/storybook)
&nbsp; - &nbsp;
🎓 [Sample repository](https://github.com/phenixdigital/phx_live_storybook_sample)

<!-- MDOC !-->

PhxLiveStorybook provides a [_storybook-like_](https://storybook.js.org) UI interface for your
Phoenix LiveView components.

- Explore all your components, and showcase them with different variations.
- Browse your component's documentation, with their supported attributes.
- Learn how components behave by using an interactive playground.

![screenshot](https://github.com/phenixdigital/phx_live_storybook/raw/main/screenshots/screenshot-01.jpg)
![screenshot](https://github.com/phenixdigital/phx_live_storybook/raw/main/screenshots/screenshot-02.jpg)

## How does it work?

PhxLiveStorybook is mounted in your application router and serves its UI at the mounting point of
your choice.

It performs automatic discovery of your storybook content under a specified folder (`:content_path`)
and then automatically generates a storybook navigation sidebar. Every module detected in your
content folder will be loaded and identified as a storybook entry.

Three kinds of stories are supported:

- `component` to describe your stateless function components or your live_components.
- `page` to write & document UI guidelines, or whatever content you want.
- `example` to show how your components can be used and mixed in real UI pages. (not available now)

## Installation

To start using `PhxLiveStorybook` in your phoenix application you will need to follow these steps:

1. Add the `phx_live_storybook` dependency
2. Create your storybook backend module
3. Add storybook access to your router
4. Make your components assets available
5. Create some content

### 1. Add the `phx_live_storybook` dependency

Add the following to your mix.exs and run mix deps.get:

```elixir
def deps do
  [
    {:phx_live_storybook, "~> 0.3.0"}
  ]
end
```

### 2. Create your storybook backend module

Create a new module under your application lib folder:

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhxLiveStorybook,
    otp_app: :my_app,
    content_path: Path.expand("../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/my_components.css",
    js_path: "/assets/my_components.js"
end
```

This backend module ensures the storybook gets recompiled as soon as you update your storybook
content (see section 6.)

### 3. Add storybook access to your router

Once installed, update your router's configuration to forward requests to a `PhxLiveStorybook`
with a unique name of your choice:

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import PhxLiveStorybook.Router
...
scope "/" do
  storybook_assets()
end

scope "/", PhxLiveStorybookSampleWeb do
  pipe_through(:browser)
  ...
  live_storybook "/storybook", backend_module: MyAppWeb.Storybook
end
```

### 4. Make your components assets available

Build a new CSS bundle dedicated to your live_view components: this bundle will be used both by your
app and the storybook.

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

ℹ️ Learn more on this topic in the [sandboxing guide](guides/sandboxing.md).

### 5. Create some content

Then you can start creating some content for your storybook. Storybook can contain different kinds
of _stories_:

- **component stories**: to document and showcase your components across different variations.
- **pages**: to publish some UI guidelines, framework or whatever with regular HTML content.
- **examples**: to show how your components can be used and mixed in real UI pages.

_As of `0.4.0`, only component and page stories are available._

Stories are described as Elixir scripts (`.story.exs`) created under your `:content_path` folder.
Feel free to organize them in sub-folders, as the hierarchy will be respected in your storybook
sidebar.

Here is an example of a stateless (function) component story:

```elixir
# storybook/components/button.story.exs
defmodule MyAppWeb.Storybook.Components.Button do
  alias MyAppWeb.Components.Button

  # :live_component or :page are also available
  use PhxLiveStorybook.Story, :component

  def function, do: &Button.button/1
  def description, do: "A simple generic button."

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

ℹ️ Learn more on components in the [components guide](guides/components.md).

### Configuration

Of all config settings, only the `:otp_app`, and `:content_path` keys are mandatory.

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhxLiveStorybook,
    # OTP name of your application.
    otp_app: :my_app,

    # Path to your storybook stories (required).
    content_path: Path.expand("../storybook", __DIR__),

    # Path to your components stylesheet.
    # Remote path, not local file-system path
    css_path: "/assets/my_components.css",

    # Path to your JS asset, which will be loaded just before PhxLiveStorybook's own
    # JS. It's mainly intended to define your LiveView Hooks in `window.storybook.Hooks`.
    # Remote path, not local file-system path.
    js_path: "/assets/my_components.js",

    # Custom storybook title. Default is "Live Storybook".
    title: "My Live Storybook",

    # Theme settings.
    # Each theme must have a name, and an optional dropdown_class.
    # When set, a dropdown is displayed in storybook header to let the user pick a theme.
    # The dropdown_class is used to render the theme in the dropdown and identify which current
    # theme is active.
    #
    # The chosen theme key will be passed as an assign to all components.
    # ex: <.component theme={:colorful}/>
    #
    # The chosen theme class will also be added to the `.lsb-sandbox` container.
    # ex: <div class="lsb-sandbox theme-colorful">...</div>
    #
    # If no theme has been selected or if no theme is present in the URL the first one is enabled.
    themes: [
      default: [name: "Default"],
      colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
    ]
```

All settings can be overridden from your config files.

```elixir
# config/config.exs
config :my_app, MyAppWeb.Storybook,
  content_path: "overridden/content/path"
```

ℹ️ Learn more on theming components in the [theming guide](guides/theming.md).

<!-- MDOC !-->

## Contributing

We would love your PRs!

1. Pull down phx_live_storybook to a directory next to your project (`../phx_live_storybook`).
2. Change your mix file to point to this directory:

```elixir
# {:phx_live_storybook, "~> 0.3.0"},
{:phx_live_storybook, path: "../phx_live_storybook"},
```

3. Update the assets in phx_live_storybook since this isn't a release

```bash
cd ../phx_live_storybook
mix deps.get
npm ci --prefix assets
mix assets.build
```

And make sure you read the [CONTRIBUTING](CONTRIBUTING.md) guide.

That should get you running against HEAD and ready to dig into the code!

## License

MIT License. Copyright (c) 2022 Christian Blavier
