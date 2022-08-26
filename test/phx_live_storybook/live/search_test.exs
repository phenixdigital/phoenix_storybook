defmodule PhxLiveStorybook.SearchTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Floki, only: [find: 2]

  alias PhxLiveStorybook.Search
  alias PhxLiveStorybook.{EmptyFilesStorybook, FlatListStorybook}

  describe "search list entries" do
    test "has no entry" do
      {_document, html} = render_search(EmptyFilesStorybook)

      assert EmptyFilesStorybook.entries() == []
      assert String.contains?(html, "No entries found")
    end

    test "contains all entries" do
      {document, html} = render_search(FlatListStorybook)

      assert find(document, "ul>li") |> length() == 2
      assert String.contains?(html, "a_component")
      assert String.contains?(html, "b_component")
    end
  end

  defp render_search(backend_module) do
    html =
      render_component(Search,
        id: "search",
        backend_module: backend_module
      )

    {:ok, document} = Floki.parse_document(html)
    {document, html}
  end
end
