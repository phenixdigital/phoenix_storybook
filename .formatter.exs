locals_without_parens = [
  live_storybook: 2
]

[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,priv}/**/*.{ex,exs,eex}",
    "test/phoenix_storybook/**/*.{ex,exs}",
    "test/*.{ex,exs}"
  ],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
