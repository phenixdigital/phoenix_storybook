# CHANGELOG

> [!IMPORTANT]
>
> **⭐ Want to help with the Phoenix Storybook project? ⭐**
>
> - I would greatly appreciate your [code contributions](https://github.com/phenixdigital/phoenix_storybook/CONTRIBUTING.md).
>
> - You can also [sponsor me](https://github.com/sponsors/cblavier), as it would enable me to dedicate my free time to fixing bugs and > developing new features 🤗

## v0.7.1 (2024-11-19)

- **bugfix**: fixed color mode switch not applying immediately on Safari

## v0.7.0 (2024-11-19)

- **feature**: [support for dark mode](https://github.com/phenixdigital/phoenix_storybook/pull/425)

## v0.6.4 (2024-09-03)

- **improvement**: [:compilation_debug config option](https://github.com/phenixdigital/phoenix_storybook/pull/496) was added in `storybook.ex` to show/hide story compilation logs
- **improvement**: fixed Elixir 1.7 related warnings

## v0.6.3 (2024-06-24)

- **improvement**: [fixed another bunch of Elixir 1.17 related warnings](https://github.com/phenixdigital/phoenix_storybook/pull/461)

## v0.6.2 (2024-06-17)

- **improvement**: [fixed Elixir 1.17 related warnings](https://github.com/phenixdigital/phoenix_storybook/pull/454)
- **bugfix**: [fixed nofile_error_due_to_missing_env issue](https://github.com/phenixdigital/phoenix_storybook/pull/449)

## v0.6.1 (2024-02-13)

- **bugfix**: [added a missing step in generator](https://github.com/phenixdigital/phoenix_storybook/issues/419)

## v0.6.0 (2024-01-05)

- **change (breaking!)**: all css `lsb-` prefixes have been renamed to `psb-` (matching `live storybook` renaming to `phoenix storybook`).
- **change (breaking!)**: [`assign` and `toggle` events have been prefixed with `psb-`](https://github.com/phenixdigital/phoenix_storybook/issues/395) (cf. `components.md` guide)
- **feature**: [render any stories with the new :one_column layout](https://github.com/phenixdigital/phoenix_storybook/issues/296)
- **improvement**: fixed compatibility with phoenix_html_helpers
- **improvement**: [function components use iframe srcdoc](https://github.com/phenixdigital/phoenix_storybook/pull/382).
- **improvement**: [Content-Security-Policy (CSP) support](https://github.com/phenixdigital/phoenix_storybook/issues/149). Special thanks to [Gaia](https://github.com/gaiabeatrice) for the PR 🙏
- **improvement**: [CSRF token is optional](https://github.com/phenixdigital/phoenix_storybook/issues/340)
- **bugfix**: [generating stories without Elixir. prefix in module names](https://github.com/phenixdigital/phoenix_storybook/issues/343)
- **bugfix**: [fixed potential import module clashes](https://github.com/phenixdigital/phoenix_storybook/issues/290)
- **bugfix**: [generated story for flash core_component has been updated (flash was no longer supporting the `autoshow` option)](https://github.com/phenixdigital/phoenix_storybook/pull/369)
- **bugfix**: [`mix phx.gen.storybook` now prints how to set the _important_ sandbox strategy](https://github.com/phenixdigital/phoenix_storybook/issues/289)
- **bugfix**: `mix phx.gen.storybook` no longer prints Docker instructions when no Docker file is present.
- **bugfix**: [dialyxir has been restored](https://github.com/phenixdigital/phoenix_storybook/issues/317)
- **bugfix**: [fixed multiple imports issue](https://github.com/phenixdigital/phoenix_storybook/issues/408)

## v0.5.7 (2023-10-05)

- **improvement**: bumped to `phoenix_live_view 0.20.0`
- **improvement**: bumped to Erlang 26 / Elixir 1.15
- **improvement**: [better router formatting and exporting formatting configuration](https://github.com/phenixdigital/phoenix_storybook/issues/332)
- **bugfix**: [fixed theme attributes being stripped out from code preview even when themes aren't being used](https://github.com/phenixdigital/phoenix_storybook/issues/352)
- **bugfix**: [updated generated story to the latest phoenix core components](https://github.com/phenixdigital/phoenix_storybook/pull/334)
- **bugfix**: [fixed white bar in code preview](https://github.com/phenixdigital/phoenix_storybook/issues/359)

## v0.5.6 (2023-07-18)

- **bugfix**: fix missing Kernel macros (such as `../0`) when evaluating stories.

## v0.5.5 (2023-07-11)

- **improvement**: [make it work with FontAwesome webfont](https://github.com/phenixdigital/phoenix_storybook/issues/306). You need to set the `font_awesome_rendering` to `:webfont` if you are not using fontawesome with
  svg icons.
- **improvement**: [fixed Elixir 1.15 deprecations](https://github.com/phenixdigital/phoenix_storybook/issues/308)

## v0.5.4 (2023-06-05)

- **bugfix**: [phx.gen.storybook alias to match storybook tailwind profile](https://github.com/phenixdigital/phoenix_storybook/pull/297).
- **bugfix**: [add LiveSocketOptions to support alpine.js](https://github.com/phenixdigital/phoenix_storybook/pull/295).

## v0.5.3 (2023-05-15)

- **bugfix**: [fixed hooks not being initialized](https://github.com/phenixdigital/phoenix_storybook/issues/268).

## v0.5.2 (2023-03-16)

- **improvement**: [improved mix phx.gen.storybook instructions](https://github.com/phenixdigital/phoenix_storybook/issues/252)
- **bugfix**: [fixed issue with nested story modules](https://github.com/phenixdigital/phoenix_storybook/issues/260).
- **bugfix**: [fixed broken generated stories](https://github.com/phenixdigital/phoenix_storybook/issues/251).
- **bugfix**: fixed theme strategy function not being called from Playground process.

## v0.5.1 (2023-03-15)

- **change (breaking!)**: LiveView `0.18.7+` is required
- **bugfix**: fixed `HTMLEngine` [issue](https://github.com/phenixdigital/phoenix_storybook/issues/262) introduced by LiveView 0.18.7.

## v0.5.0 (2023-02-27)

- **change (breaking!)**: project has been renamed from `phx_live_storybook` to `phoenix_storybook`. In your project:
  - rename all references of `phx_live_storybook` to `phoenix_storybook`
  - rename all references from `PhxLiveStorybook` to `PhoenixStorybook`
- **change (breaking!)**: depends on `phoenix 1.7+`
- **change (breaking!)**: [component description is no longer a function defined](https://github.com/phenixdigital/phoenix_storybook/issues/138)
  in your story file but is fetched from your component `@doc` or your live_component `@moduledoc`
  comments.
- **feature**: [support for Example stories](https://github.com/phenixdigital/phoenix_storybook/issues/213)
- **feature**: [visual regression endpoints](https://github.com/phenixdigital/phoenix_storybook/issues/215).
  This endpoint can output bare components without the storybook's UI so that you can automate
  visual tests screenshots.
- **improvement**: [mix phx.gen.storybook now prints formatter instructions](https://github.com/phenixdigital/phoenix_storybook/issues/153)
- **improvement**: [new theme strategies](https://github.com/phenixdigital/phoenix_storybook/issues/177). Theming guide has been updated.
- **improvement**: [boolean attributes are rendered with their shorthand notation](https://github.com/phenixdigital/phoenix_storybook/issues/169)
- **improvement**: [generating stories for Phoenix 1.7 core components](https://github.com/phenixdigital/phoenix_storybook/issues/187)
- **bugfix**: [a project without heroicons will no longer raise on the generated icon story](https://github.com/phenixdigital/phoenix_storybook/issues/152)
- **bugfix**: [fixed variation crash with a large binary in a map](https://github.com/phenixdigital/phoenix_storybook/pull/161)
- **bugfix**: [fixed slots crash if rendered more than once ](https://github.com/phenixdigital/phoenix_storybook/issues/206)

## v0.4.5 (2022-10-10)

- **bugfix**: `TemplateHelpers.unique_variation_id/2` raises in playground if component has an `id` attr.
- **bugfix**: fixed some dialyxir warnings

## v0.4.4 (2022-10-10)

- **feature**: [you can now customize your story div container](https://github.com/phenixdigital/phoenix_storybook/issues/135)
- **improvement**: [removed routes helpers](https://github.com/phenixdigital/phoenix_storybook/pull/137)
  (will help transition to Phoenix 1.7)
- **improvement**: [pass connect params to story page](https://github.com/phenixdigital/phoenix_storybook/pull/130)
- **bugfix**: [add :live_session and :as options to router](https://github.com/phenixdigital/phoenix_storybook/pull/127)
- **bugfix**: [missing playground tab icons](https://github.com/phenixdigital/phoenix_storybook/issues/134)

## v0.4.3 (2022-10-04)

- **bugfix**: [mounting several storybooks in router is now possible](https://github.com/phenixdigital/phoenix_storybook/issues/126)
- **bugfix**: fixed mobile layout

## v0.4.2 (2022-10-02)

- **improvement**: upgraded to LiveView 0.18.1
- **improvement**: improved generated storybook component & page

## v0.4.1 (2022-09-30)

- **bugfix**: sidebar, tabs & theme icon [rendering issues have been fixed](https://github.com/phenixdigital/phoenix_storybook/issues/111). Icons are no longer rendered within the CSS sandbox and should be
  styles with `lsb-*` classes.
- **bugfix**: [search panel no longer binds the `/` key](https://github.com/phenixdigital/phoenix_storybook/issues/110).
- **bugfix**: [component generated by the `mix phx.gen.storybook` is no longer crashing.](https://github.com/phenixdigital/phoenix_storybook/pull/116)

## v0.4.0 (2022-09-29)

A lot of necessary changes & refactoring have been made in this release which now requires you to
run it with brand new **LiveView 0.18.0**.

This is the first release containing feedbacks & contribution from outside users! Thank you all! 🔥

- **change (breaking!)**: LiveView 0.18.0 is required. Attributes & slots declared in your components
  are supported by the component Playground.
- **change (breaking!)**: configuration has been moved from config.exs files to your elixir backend module.
- **change (breaking!)**: `stories` have been re-rebranded as `variations`, `Story` became `Variation`
  and `StoryGroup` became `VariationGroup`
- **change (breaking!)**: `entries` have been re-rebranded as `stories`.
- **change (breaking!)**: story (former entry) files must be created in `*.story.exs` files.
- **change (breaking!)**: sidebar custom story names and icons are now defined in `*.index.exs` files.
- **change (breaking!)**: `live_storybook/2` is no longer serving assets. You must add
  `storybook_assets/1` to your router in a non CSRF-protected scope.
- **change (breaking!)**: attr `options` have been renamed to `examples`. A new `values` key is also
  available to enforce variation attribute values.
- **change (breaking!)**: slots & block are no longer attributes. Define instead a `slots/0` function
  returning a list of `%Slot{}`.
- **change (breaking!)**: icon format has been updated, see this [guide](guides/icons.md)
- **feature**: run `mix phx.gen.storybook` to get started!
- **feature**: new search modal. Trigger it with `cmd-k` or `/` shortcuts.
- **feature**: new event log. In the playground, you can now track all events emitted by components.
- **feature**: theming. You can declare different themes in the application settings. The selected
  theme will be merged in all components assigns.
- **feature**: you can initialize the component playground with any variation.
- **feature**: templates. You can provide HTML templates to render stories, which can help with modals,
  slide-overs... (see this [guide](guides/components.md) for more details).
- **feature**: provide custom aliases & imports to your stories/templates
  (see this [guide](guides/components.md) for more details).
- **feature**: you can provide a `let` attribute to your inner blocks.
- **feature**: you can use late evaluation with `{:eval, val}` if you want to preserve the original
  expression in code preview.
- **improvement**: stories compilation is lazy in dev environment (and eager in other envs). This
  behavior can be tweaked with the `:compilation_mode` config key.
- **improvement**: storybook playground is now responsive.
- **bugfix**: fixed pre-opened folders always reopening themselves after each patch.
- **bugfix**: empty inner_block are no longer passed to all components.
- **bugfix**: fixed closing tag typo in code preview.
- **documentation**: new [`theming.md`](guides/theming.md) guide.
- **documentation**: new [`components.md`](guides/components.md) guide.

## v0.3.0 (2022-08-18)

- **change (breaking!)**: entries must now be written as `.exs` files. Otherwise, they will be ignored.
- **change (breaking!)**: `variations` have been rebranded as `stories`.
- **change (breaking!)**: `live_storybook/2` must be set in your `router.ex` outside your main scope
  and outside your `:browser` pipeline.
- **feature**: new Playground tab to play with your components! To use it, you must declare attributes
  in your component entries.
- **feature**: you can opt-in iframe rendering for any of your components with `def container, do: :iframe`
- **improvement**: storybook is now fully responsive.
- **improvement**: meaningful errors are raised during compilation if your entries are invalid.
- **improvement**: improved storybook CSS isolation. It should no longer leak within your components.
- **improvement**: stateless component entries no longer require defining a `component/0` function.
- **documentation**: new [`sandboxing.md`](guides/sandboxing.md) guide.

## v0.2.0 (2022-07-30)

- **feature**: new tab to browse your component sources
- **feature**: work-in-progress component documentation tab
- **feature**: new page entry support, which allows you create custom pages within your storybook
- **improvement**: introduced `%VariationGroup{}` to render mulitple variations in a single page div.

## v0.1.0 (2022-07-26)

Initial release.
