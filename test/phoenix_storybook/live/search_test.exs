defmodule PhoenixStorybook.SearchTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import LazyHTML, only: [query: 2]

  alias PhoenixStorybook.Search
  alias PhoenixStorybook.{EmptyFilesStorybook, FlatListStorybook}

  describe "search list stories" do
    test "has no story" do
      {_document, html} = render_search(EmptyFilesStorybook)
      assert String.contains?(html, "No stories found")
    end

    test "contains all stories" do
      {document, html} = render_search(FlatListStorybook)

      assert query(document, "ul>li") |> LazyHTML.to_tree() |> length() == 2
      assert String.contains?(html, "a_component")
      assert String.contains?(html, "b_component")
    end
  end

  defp render_search(backend_module) do
    html =
      render_component(Search,
        id: "search",
        root_path: "/storybook",
        backend_module: backend_module
      )

    document = LazyHTML.from_document(html)
    {document, html}
  end
end
