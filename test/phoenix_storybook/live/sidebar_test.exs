defmodule PhoenixStorybook.SidebarTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  import LazyHTML, only: [query: 2]
  alias PhoenixStorybook.Sidebar
  alias PhoenixStorybook.{FlatListStorybook, TreeStorybook}

  describe "storybook with flat list of stories" do
    test "sidebar contains those 2 stories" do
      {document, _html} = render_sidebar(FlatListStorybook)
      # test sidebar has 1 root story
      assert query(document, "nav>ul>li") |> LazyHTML.to_tree() |> length() == 1

      # test sidebar has 2 folders beneath root
      assert query(document, "nav>ul>li>ul>li") |> LazyHTML.to_tree() |> length() == 2

      # test those 2 stories are links (ie. not folders)
      assert query(document, "nav>ul>li>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 2
    end
  end

  describe "storybook with a tree of stories" do
    test "sidebar contains all stories, with one open folder" do
      {document, _html} = render_sidebar(TreeStorybook)
      sidebar = query(document, "nav>ul>li")

      # test sidebar has 1 root story
      assert length(LazyHTML.to_tree(sidebar)) == 1

      # test sidebar has 11 stories
      assert query(document, "nav>ul>li>ul>li") |> LazyHTML.to_tree() |> length() == 11

      # test 4 of them are links (ie. not folders)
      assert query(document, "nav>ul>li>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 4

      # first node (which is 1st folder) is closed
      assert query(document, "nav>ul>li>ul>li:nth-child(1)>ul>li")
             |> LazyHTML.to_tree()
             |> length() == 0

      # second node (which is 2nd folder) is open (by config)
      assert query(document, "nav>ul>li>ul>li:nth-child(2)>ul>li")
             |> LazyHTML.to_tree()
             |> length() == 4
    end

    test "sidebar with a path contains all stories, with 2 open folders" do
      {document, _html} = render_sidebar(TreeStorybook, "/a_folder/aa_component")
      # test sidebar has 1 root story
      assert query(document, "nav>ul>li") |> LazyHTML.to_tree() |> length() == 1

      # test sidebar has 11 stories
      assert query(document, "nav>ul>li>ul>li") |> LazyHTML.to_tree() |> length() == 11

      # test 4 of them are links (ie. not folders)
      assert query(document, "nav>ul>li>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 4

      # first node (which is 1st folder) is open (by path)
      assert query(document, "nav>ul>li>ul>li:nth-child(1)>ul>li")
             |> LazyHTML.to_tree()
             |> length() == 2

      # second node (which is 2nd folder) is open (by config)
      assert query(document, "nav>ul>li>ul>li:nth-child(2)>ul>li")
             |> LazyHTML.to_tree()
             |> length() == 4
    end

    test "sidebar with a path has active story marked as active" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      # test 1th story in 1st folder is active (font-bold class)
      [{"div", [{"class", link_class} | _], _}] =
        query(document, "nav>ul>li>ul>li:nth-child(1)>ul>li:nth-child(1)>div")
        |> LazyHTML.to_tree()

      assert String.contains?(link_class, "psb:font-bold")
    end

    test "sidebar with an icon folder is well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      [
        {"i", [{"class", first_icon_classes} | _], _},
        {"i", [{"class", second_icon_classes} | _], _}
      ] = query(document, "nav>ul>li>ul>li:nth-child(1)>div>i") |> LazyHTML.to_tree()

      assert String.contains?(first_icon_classes, "fa-caret-down")
      assert String.contains?(second_icon_classes, "fa-icon")
    end

    test "sidebar folder names are well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      # test default folder name (properly humanized)
      [{"span", [_], [html]}] =
        query(document, "nav>ul>li>ul>li:nth-child(1)>div>span:nth-child(3)")
        |> LazyHTML.to_tree()

      assert String.contains?(html, "A Folder")

      # test config folder name
      [{"span", [_], [html]}] =
        query(document, "nav>ul>li>ul>li:nth-child(2)>div>span") |> LazyHTML.to_tree()

      assert String.contains?(html, "Config Name")
    end
  end

  defp render_sidebar(backend_module, path \\ "/") do
    html =
      render_component(Sidebar,
        id: "sidebar",
        backend_module: backend_module,
        root_path: "/storybook",
        current_path: path,
        fa_plan: :pro,
        sandbox_class: "sandbox"
      )

    document = LazyHTML.from_document(html)
    {document, html}
  end
end
