# Component entries

Basic component documentation is in `PhxLiveStorybook.Entry`.

## Story groups

You may want to present different variations of a component in a single story block.
It is possible using `PhxLiveStorybook.StoryGroup`.

## Container

By default, each `story` is rendered within a `div` in the storybook DOM.
If you need further _sandboxing_ you can opt in for `iframe` rendering.

```elixir
# storybook/my_component.exs
defmodule Storybook.MyComponent do
  use PhxLiveStorybook.Entry, :component

  def function, do: &MyComponent.my_component/1
  def container, do: :iframe
end
```

ℹ️ Learn more on this topic in the [sandboxing guide](guides/sandboxing.md).

## Aliases & Imports

When using nested components or JS commands, you might need to reference other functions or
components. Whilst it is possible to use fully qualified module names, you might want to provide
custom _aliases_ and _imports_.

Here is an example defining both:

```elixir
defmodule NestedComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &NestedComponent.nested_component/1

  def aliases, do: [MyStorybook.Helpers.JSHelpers]
  def imports, do: [{NestedComponent, nested: 1}]

  def stories do
    [
      %Story{
        id: :default,
        block: """
        <.nested phx-click={JSHelpers.toggle()}>hello</.nested>
        <.nested phx-click={JSHelpers.toggle()}>world</.nested>
        """
      }
    ]
  end
end
```

## Outer templates

Some components, such as _modals_, _slideovers_, and _notifications_, are not visible from the
start: they first need user interaction.

Such components can be accompanied by an outer template, that will for instance render a button next
to the component, to toggle its visibility state.

### JS-controlled visibility

The simplest case is when component visibility is controlled client-side, by toggling CSS
classes/attributes through [JS commands](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html).

```elixir
defmodule Storybook.Components.Modal do
  use PhxLiveStorybook.Entry, :component

  def function, do: &Components.Modal.modal/1

  def template do
    """
    <div>
      <button phx-click={Modal.show_modal()}>Open modal</button>
      <.story/>
    </div>
    """
  end

  def stories do
    [
      %Story{
        id: :default_modal,
        slots: ["<:body>hello world</:body>"]
      }
    ]
  end
end
```

Every story will be rendered within the defined template, the story itself is injected in place of
`<.story/>`.

### Elixir-controlled visibility

Some components don't rely on JS commands but need external assigns, like a modal that takes a
`show={true}` or `show={false}` assign to manage its visibility state.

`PhxLiveStorybook` handles special `set-story-assign/*` and `toggle-story-assign/*` events that you
can leverage to update properties that will be passed to your components as _extra assigns_.

Syntax is:

- **set value**: `set-story-assign/:story_id/:assign_id/:assign_value`.
- **toggle value**: `toggle-story-assign/:story_id/:assign_id`.

When used from the template, the `:story_id` will be dynamically replaced at render time.

```elixir
defmodule Storybook.Components.Slideover do
  use PhxLiveStorybook.Entry, :component
  def function, do: &Components.Slideover.slideover/1

  def template do
    """
    <div>
      <button phx-click="set-story-assign/:story_id/show/true">
        Open slideover
      </button>
      <.story/>
    </div>
    """
  end

  def stories do
    [
      %Story{
        id: :default_slideover,
        attributes: %{
          close_event: "set-story-assign/default_slideover/show/false"
        },
        slots: ["<:body>Hello world</:body>"]
      }
    ]
  end
end
```
