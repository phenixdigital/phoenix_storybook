# Used by "mix format"
[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,priv}/**/*.{ex,exs,eex}",
    "test/phoenix_storybook/**/*.{ex,exs}",
    "test/*.{ex,exs}"
  ]
]
