defmodule PhxLiveStoryBook.Guides do
  @moduledoc """
  This module is meant to be used from generated `welcome.story.exs` page.
  It renders HTML markup from markdown guides located in the guides/folder.

  Markup is precompiled because:
  - we don't want to force user application to embed Earmark
  - we don't wont to put markdown guides in priv

  ## Examples

  ```elixir
  Guides.markup("components.md")
  Guides.markup("icons.md")
  ```
  """

  use PhxLiveStoryBook.Guides.Macros
end
