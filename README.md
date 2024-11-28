# PhoenixStorybook

[![github](https://github.com/phenixdigital/phoenix_storybook/actions/workflows/elixir.yml/badge.svg)](https://github.com/phenixdigital/phoenix_storybook/actions/workflows/elixir.yml)
[![codecov](https://codecov.io/gh/phenixdigital/phoenix_storybook/branch/main/graph/badge.svg)](https://codecov.io/gh/phenixdigital/phoenix_storybook)
[![GitHub release](https://img.shields.io/github/v/release/phenixdigital/phoenix_storybook.svg)](https://hex.pm/packages/phoenix_storybook)

📚 [Documentation](https://hexdocs.pm/phoenix_storybook)
&nbsp; - &nbsp;
🔎 [Demo](https://phoenix-storybook-demo.fly.dev/)
&nbsp; - &nbsp;
🎓 [Sample app](https://github.com/phenixdigital/phoenix_storybook_sample)
&nbsp; - &nbsp;
🍿 [Getting started video](https://www.youtube.com/watch?v=MTE7dLhkQ8Q)
&nbsp; - &nbsp;
🦊 [ElixirCasts](https://elixircasts.io/phoenix-storybook)

---

<a href='https://ko-fi.com/C0C316P9FN' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

_I'm the sole maintainer of this project and work on it in my free time. Any tips would be appreciated!_

---

<!-- MDOC !-->

PhoenixStorybook provides a [_storybook-like_](https://storybook.js.org) UI interface for your
Phoenix components.

- Explore all your components, and showcase them with different variations.
- Browse your component's documentation, with their supported attributes.
- Learn how components behave by using an interactive playground.

![screenshot](https://github.com/phenixdigital/phoenix_storybook/raw/main/screenshots/screenshot-01.jpg)
![screenshot](https://github.com/phenixdigital/phoenix_storybook/raw/main/screenshots/screenshot-02.jpg)

## How does it work?

PhoenixStorybook is mounted in your application router and serves its UI at the mounting point of
your choice.

It performs automatic discovery of your storybook content under a specified folder (`:content_path`)
and then automatically generates a storybook navigation sidebar. Every module detected in your
content folder will be loaded and identified as a storybook entry.

Three kinds of stories are supported:

- `component` to describe your stateless function components or your live_components.
- `page` to write & document UI guidelines, or whatever content you want.
- `example` to show how your components can be used and mixed in real UI pages.

## Installation

To start using `PhoenixStorybook` in your phoenix application you will need to follow these steps:

1. Add the `phoenix_storybook` dependency
2. Run the generator

### 1. Add the `phoenix_storybook` dependency

Add the following to your mix.exs and run mix deps.get:

```elixir
def deps do
  [
    {:phoenix_storybook, "~> 0.7.0"}
  ]
end
```

> [!IMPORTANT]
>
> When picking a github version of the library (instead of an official hex.pm release) you
> need the get the storybook's assets compiled.
> To do so, please run `mix dev.storybook`.

### 2. Run the generator

Run from the root of your application:

```bash
$> mix deps.get
$> mix phx.gen.storybook
```

And you are ready to go!

ℹ️ If you prefer manual setup, please read the [setup guide](guides/setup.md).

### Configuration

Of all config settings, only the `:otp_app`, and `:content_path` keys are mandatory.

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhoenixStorybook,
    # OTP name of your application.
    otp_app: :my_app,

    # Path to your storybook stories (required).
    content_path: Path.expand("../storybook", __DIR__),

    # Path to your JS asset, which will be loaded just before PhoenixStorybook's own
    # JS. It's mainly intended to define your LiveView Hooks in `window.storybook.Hooks`.
    # Remote path (not local file-system path) which means this file should be served
    # by your own application endpoint.
    js_path: "/assets/storybook.js",

    # Path to your components stylesheet.
    # Remote path (not local file-system path) which means this file should be served
    # by your own application endpoint.
    css_path: "/assets/storybook.css",

    # This CSS class will be put on storybook container elements where your own styles should
    # prevail. See the `guides/sandboxing.md` guide for more details.
    sandbox_class: "my-app-sandbox",

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
    # The chosen theme class will also be added to the `.psb-sandbox` container.
    # ex: <div class="psb-sandbox theme-colorful">...</div>
    #
    # If no theme has been selected or if no theme is present in the URL the first one is enabled.
    themes: [
      default: [name: "Default"],
      colorful: [name: "Colorful", dropdown_class: "text-pink-400"]
    ],

    # Color mode settings. Defaults to false and 'dark'.
    color_mode: true,
    color_mode_sandbox_dark_class: "dark",

    # If you want to use custom FontAwesome icons.
    font_awesome_plan: :pro, # default value is :free
    font_awesome_kit_id: "foo8b41bar4625",
    font_awesome_rendering: :webfont, # default value is :svg

    # Story compilation mode, can be either `:eager` or `:lazy`.
    # It defaults to `:lazy` in dev environment, `:eager` in other environments.
    #   - When eager: all .story.exs & .index.exs files are compiled upfront.
    #   - When lazy: only .index.exs files are compiled upfront and .story.exs are compile when the
    #     matching story is loaded in UI.
    compilation_mode: :eager,

    # If you want to see debugging logs for storybooks compilation, set this to `true`. Default: `false`
    compilation_debug: true
  ]
```

All settings can be overridden from your config files.

```elixir
# config/config.exs
config :my_app, MyAppWeb.Storybook,
  content_path: "overridden/content/path"
```

ℹ️ Learn more on theming components in the [theming guide](guides/theming.md), icons in the
[icons](guides/icons.md) guide and color mode in the [color modes guide](guides/color_modes.md).

<!-- MDOC !-->

## Storybook in production

A few storybooks running in production:

- [Phenix Groupe](https://storybook.phenixgroupe.com/)
- [SaladUI](https://salad-storybook.fly.dev/)
- [Doggo](https://woylie-doggo.fly.dev/)
- [Tremorx](https://tremorx.fly.dev/)
- [Bloom](https://bloom-ui.fly.dev/)

## Contributing

We would love your PRs!

1. Pull down phoenix_storybook to a directory next to your project (`../phoenix_storybook`).
2. Change your mix file to point to this directory:

```elixir
{:phoenix_storybook, path: "../phoenix_storybook"},
```

3. Run dev.storybook mix task from your project

```bash
$> mix dev.storybook
```

And make sure you read the [CONTRIBUTING](CONTRIBUTING.md) guide.
That should get you running against HEAD and ready to dig into the code!

## License

MIT License. Copyright (c) 2022
