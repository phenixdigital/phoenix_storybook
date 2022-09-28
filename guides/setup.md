## Manual setup

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
    {:phx_live_storybook, "~> 0.4.0"}
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

In this README, we use `assets/css/storybook.css` as an example.

If your components require any hooks or custom uploaders, declare them as such in a new JS bundle:

```javascript
// assets/js/storybook.js

import * as Hooks from "./hooks";
import * as Uploaders from "./uploaders";

(function () {
  window.storybook = { Hooks, Uploaders };
})();
```

These assets must be bundled and served by your own application. Our custom `mix phx.gen.storybook`
generator may guide you through these steps.

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
