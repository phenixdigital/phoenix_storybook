# PhxLiveStorybook

PhxLiveStorybook provides a [_storybook-like_](https://storybook.js.org) UI interface for your Phoenix LiveView components.

- Explore all your components, and showcase them with different variations.
- Browse your components documentation, with their supported attributes.
- Learn how components behave by using an interactive playground.

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
    {:phx_live_storybook, "~> 0.1.0"}
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
  content_path: Path.expand("../my_app_web/lib/storybook", __DIR__),
  css_path: "/assets/my_components.css",
  js_path: "/assets/my_components.js"
```

### 6. Create some content.

Then you can start creating some content for your storybook. Storybook can contain 3 different kind of _entries_:

- **component entries**: to document and showcase your components.
- **pages**: to publish some UI guidelines, framework or whatever with regular HTML content.
- **samples**: to show how your components can be used and mixed togethers in real UI pages.

_As of `0.1.0`, only component entries are available._

Entries are described as regular Elixir modules, created under your `:content_path` folder. Feel free to organize them in sub-folders, as the hierarchy will be respected in your storybook sidebar.

Here is an example of a stateless (function) component entry:

```elixir
# lib/my_app_web/storybook/components/button.ex

defmodule MyAppWeb.Storybook.Components.Button do
  alias MyAppWeb.Components.Button

  use PhxLiveStorybook.Component

  def component, do: Button
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

### License

MIT License. Copyright (c) 2022 Christian Blavier
