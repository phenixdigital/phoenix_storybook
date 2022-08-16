# CHANGELOG

## v0.3.0 (not released)

- change (breaking!): entries must know be written as `.exs` files. Otherwise they will be ignored.
- change (breaking!): `variations` have been rebranded as `stories`.
- change (breaking!): `live_storybook/2` must be set in your `router.ex` outside of your main scope  
  and outside of your `:browser` pipeline.
- feature: new Playground tab to play with your components! To use it, you just need to declare
  attributes in your component entries.
- feature: you can opt-in iframe rendering for any of your component
- improvement: storybook is now fully responsive.
- improvement: meaningful errors are raised during compilation if your entries are invalid.
- improvement: improved storybook CSS isolation. It should no longer leak within your components.
- improvement: stateless component entries no longer require to define a `component/0` function.
- documentation: new `sandboxing.md` guide.

## v0.2.0 (2022-07-30)

- feature: new tab to browse your component sources
- feature: work-in-progress component documentation tab
- feature: new page entry support, which allows you create custom pages within your storybook
- improvement: introduced `%VariationGroup{}` to render mulitple variations in a single page div.

## v0.1.0 (2022-07-26)

Initial release.
