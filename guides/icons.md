# Custom Icons

You can provide custom sidebar & header icons for your stories.
Page stories can also provide iconized navigation tabs.

PhxLiveStorybook gives you the ability to render icons with 2 different providers:

- [FontAwesome](https://fontawesome.com) which offers a decent set of free icons and a lot of
  additional styles with paid plans
- [HeroIcons](https://heroicons.com) wich offer hundreds of free high quality icons

## Declaring an icon

Whenever you provide an icon to the storybook, you should follow the following structure:
`{:icon_provider, icon_name, :icon_style, additional_css_classes}`.

The two last tuple elements are optional.

```elixir
{:fa, "book"} # note that the FontAwesome icon name omits the fa- prefix
{:fa, "book", :solid} # same than previous one, :solid is the default style
{:fa, "skull", :duotone} # only for FontAwesome paid users
{:fa, "skull", :duotone, "lsb-px-2"}
{:hero, "cake"} # for all HeroIcons
{:hero, "cake", :outline} # same than previous one, :outline is the default style
{:hero, "cake", :outline, "lsb-w-2 lsb-h-2"}
```

## FontAwesome icons

PhxLiveStorybook is built with a very small subset of FontAwesome free icons. If you want to use
other FontAwesome icons you need to provide a valid **FontAwesome kit id**.

It can be either free or paid, so you also need to configure your FontAwesome plan.

```elixir
# lib/my_app_web/storybook.ex
defmodule MyAppWeb.Storybook do
  use PhxLiveStorybook,
    otp_app: :my_app,
    font_awesome_plan: :pro, # default value is :free
    font_awesome_kit_id: "foo8b41bar4625",
end
```

## HeroIcons

PhxLiveStorybook delegates icon rendering to [heroicons_elixir](https://github.com/mveytsman/heroicons_elixir).
Make sure to add their dependency in your `mix.exs` file.

```elixir
defp deps do
  [
    {:heroicons, "~> 0.5.0"}
  ]
end
```

You can now use whichever HeroIcon icon you want, based on the library function names.

## Custom CSS

The last tuple argument is an optional CSS class list you can pass to improve icon rendering.
Since the icon is rendered within the storybook layout, and not within your components sandbox, you
should use CSS classes supported by the storybook.

- any `lsb-w-*` or `lsb-h-*` class (TailwindCSS classes for height & width prefixed by `lsb-`)
- any `lsb-p-*` or `lsb-m-*` class (padding & margin)
- any `lsb-text-color-###`
- any `fa-*` (FontAwesome modifiers)
