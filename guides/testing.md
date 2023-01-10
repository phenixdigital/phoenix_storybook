# Visual Regression Testing

While we still encourage you writing regular unit test for your components, this doesn't protect
you against visual regressions.

Visual Regression Testing consists in taking automated screenshots of your components and compare
them pixel-per-pixel to notice any unwanted change.

For this we recommend using a dedicated tool such as [percy.io](https://percy.io/).

This library provides you a dedicated enpoint to output your stories (only components' stories)
without the storybook main UI:

- single story endpoint: `https://localhost:4000/storybook/visual_tests/buttons/button`
- range story endpoint: `https://localhost:4000/storybook/visual_tests?start=a&end=e`

_The last one renders all stories whose name starting between letter 'a' and letter 'e')_
