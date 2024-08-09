defmodule PhoenixStorybook.Guides do
  @moduledoc """
  This module is meant to be used from generated `welcome.story.exs` page.
  It renders HTML markup from markdown guides located in the guides/folder.

  Markup is precompiled because:
  - we don't want to force user application to embed Earmark
  - we don't want to put markdown guides in priv

  ## Examples

  ```elixir
  Guides.markup("components.md")
  Guides.markup("icons.md")
  ```
  """

  use PhoenixStorybook.Guides.Macros
end
