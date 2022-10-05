defmodule PhxLiveStorybook.SearchTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Floki, only: [find: 2]

  alias PhxLiveStorybook.Search
  alias PhxLiveStorybook.{EmptyFilesStorybook, FlatListStorybook}

  describe "search list stories" do
    test "has no story" do
      {_document, html} = render_search(EmptyFilesStorybook)
      assert String.contains?(html, "No stories found")
    end

    test "contains all stories" do
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
        root_path: "/storybook",
        backend_module: backend_module
      )

    {:ok, document} = Floki.parse_document(html)
    {document, html}
  end
end
