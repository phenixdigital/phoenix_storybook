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

ℹ️ Learn more on this topic in the [sandboxing guide](sandboxing.md).

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

## Templates

You may want to render your components within some wrapping markup. For instance, when your
component can only be used as a block or slot of another wrapping component.

Some components, such as _modals_, _slideovers_, and _notifications_, are not visible from the
start: they first need user interaction. Such components can be accompanied by an outer template,
that will for instance render a button next to the component, to toggle its visibility state.

### Story templates

You can define a template in your component entry by defining a `template/0` function.
Every story will be rendered within the defined template, the story itself is injected in place of
`<.lsb-story/>`.

```elixir
def template do
  """
  <div class="my-custom-wrapper">
    <.lsb-story/>
  </div>
  """
end
```

You can also override the template, per story or story_group by setting the `:template` key to your
story. Setting it to a falsy value will disable templating for this story.

### Story group templates

Story groups can also leverage on templating:

- either by wrapping every story in their own template.

```elixir
"""
<div class="one-wrapper-for-each-story">
  <.lsb-story/>
</div>
"""
```

- or by wrapping all stories as a whole, in a single template.

```elixir
"""
<div class="a-single-wrapper-for-all">
  <.lsb-story-group/>
</div>
"""
```

If you want to get unique id, you can use `:story_id` that will be replaced, at rendering time by
the current story (or story group) id.

### Placeholder attributes

In template, you can pass some extra attributes to your story. Just add them to the `.lsb-story` or
`.lsb-story-group` placeholder.

```elixir
"""
<.form_for for={:user} let={f}>
  <.lsb-story form={f}/>
</.form>
"""
```

### JS-controlled visibility

Here is an example of templated component managing its visibility client-side, by toggling CSS
classes through [JS commands](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html).

```elixir
defmodule Storybook.Components.Modal do
  use PhxLiveStorybook.Entry, :component

  def function, do: &Components.Modal.modal/1

  def template do
    """
    <div>
      <button phx-click={Modal.show_modal()}>Open modal</button>
      <.lsb-story/>
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

### Elixir-controlled visibility

Some components don't rely on JS commands but need external assigns, like a modal that takes a
`show={true}` or `show={false}` assign to manage its visibility state.

`PhxLiveStorybook` handles special `assign` and `toggle` events that you
can leverage on to update some properties that will be passed to your components as _extra assigns_.

```elixir
defmodule Storybook.Components.Slideover do
  use PhxLiveStorybook.Entry, :component
  def function, do: &Components.Slideover.slideover/1

  def template do
    """
    <div>
      <button phx-click={JS.push("assign", value: %{show: true})}>
        Open slideover
      </button>
      <.lsb-story/>
    </div>
    """
  end

  def stories do
    [
      %Story{
        id: :default_slideover,
        attributes: %{
          close_event: JS.push("assign", value: %{story_id: :default_slideover, show: false})
        },
        slots: ["<:body>Hello world</:body>"]
      }
    ]
  end
end
```

### Template code preview

By default, the code preview will render the story and its template markup as well.
You can choose to render only the story markup, without its surrounding template by using the
`lsb-code-hidden` HTML attribute.

```elixir
"""
<div lsb-code-hidden>
  <button phx-click={Modal.show_modal()}>Open modal</button>
  <.lsb-story/>
</div>
"""
```

## Block, slots & let

Liveview let you define inner blocks in your components, which are either named `slots` or the
default `inner block`.

They can be passed in your stories with the `:block` and `:slots` keys :

```elixir
%Story{
  id: :modal,
  block: "<p>My modal body</p>",
  slots: [
    """
    <:button>
      <button type="button">Cancel</button>
    </:button>
    """,
    """
    <:button>
      <button type="button">OK</button>
    </:button>
    """
  ]
}
```

You can also use [LiveView let mechanism](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#module-default-slots)
to pass data to your default block. You just need to **declare the let attribute** you are using in
your story.

```elixir
%Story{
  id: :list,
  attributes: %{entries: ~w(apple banana cherry)},
  let: :entry,
  block: "I like <%= entry %>"
}
```

`let` syntax can also be used with named slots, but requires no specific livebook setup.

```elixir
%Story{
  id: :table,
  attributes: %{
    rows: [
      %{first_name: "Jean", last_name: "Dupont"},
      %{first_name: "Sam", last_name: "Smith"}
    ]
  },
  slots: [
    """
    <:col let={user} label="First name">
      <%= user.first_name %>
    </:col>
    """,
    """
    <:col let={user} label="Last name">
      <%= user.last_name %>
    </:col>
    """
  ]
}
```
