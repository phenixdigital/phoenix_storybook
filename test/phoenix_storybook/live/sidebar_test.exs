defmodule PhoenixStorybook.SidebarTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  import LazyHTML, only: [query: 2]
  alias PhoenixStorybook.Sidebar
  alias PhoenixStorybook.{FlatListStorybook, TreeStorybook}

  describe "storybook with flat list of stories" do
    test "sidebar contains those 2 stories" do
      {document, html} = render_sidebar(FlatListStorybook)

      # test sidebar has 2 stories at the root
      assert query(document, "nav>ul>li") |> LazyHTML.to_tree() |> length() == 2

      # test those 2 stories are links (ie. not folders)
      assert query(document, "nav>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 2

      refute html =~ ">Storybook<"
    end
  end

  describe "storybook with a tree of stories" do
    test "sidebar contains all stories, with one open folder" do
      {document, _html} = render_sidebar(TreeStorybook)
      # test sidebar has 11 stories at the root
      assert query(document, "nav>ul>li") |> LazyHTML.to_tree() |> length() == 11

      # test 4 of them are links (ie. not folders)
      assert query(document, "nav>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 4

      # first node (which is 1st folder) is closed
      assert query(document, "div[phx-value-path='/storybook/a_folder'] + div ul>li")
             |> LazyHTML.to_tree()
             |> length() == 0

      # second node (which is 2nd folder) is open (by config)
      assert query(document, "div[phx-value-path='/storybook/b_folder'] + div ul>li")
             |> LazyHTML.to_tree()
             |> length() == 4
    end

    test "sidebar with a path contains all stories, with 2 open folders" do
      {document, _html} = render_sidebar(TreeStorybook, "/a_folder/aa_component")
      # test sidebar has 11 stories at the root
      assert query(document, "nav>ul>li") |> LazyHTML.to_tree() |> length() == 11

      # test 4 of them are links (ie. not folders)
      assert query(document, "nav>ul>li>div>a") |> LazyHTML.to_tree() |> length() == 4

      # first node (which is 1st folder) is open (by path)
      assert query(document, "div[phx-value-path='/storybook/a_folder'] + div ul>li")
             |> LazyHTML.to_tree()
             |> length() == 2

      # second node (which is 2nd folder) is open (by config)
      assert query(document, "div[phx-value-path='/storybook/b_folder'] + div ul>li")
             |> LazyHTML.to_tree()
             |> length() == 4
    end

    test "sidebar with a path has active story marked as active" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      # test 1st story in 1st folder is active (font-bold class)
      assert query(
               document,
               "div[class*='psb:font-bold']>a[href='/storybook/a_folder/component']"
             )
             |> LazyHTML.to_tree()
             |> length() == 1
    end

    test "sidebar only displays the gutter for nested stories" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      assert query(
               document,
               "nav>ul>li>div[class*='border-l']>a[href='/storybook/a_page']"
             )
             |> LazyHTML.to_tree()
             |> Enum.empty?()

      assert query(
               document,
               "nav ul ul div[class*='border-l']>a[href='/storybook/a_folder/component']"
             )
             |> LazyHTML.to_tree()
             |> length() == 1
    end

    test "sidebar with an icon folder is well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      [
        {"i", [{"class", first_icon_classes} | _], _},
        {"i", [{"class", second_icon_classes} | _], _}
      ] =
        query(document, "div[phx-value-path='/storybook/a_folder'] i")
        |> LazyHTML.to_tree()

      assert String.contains?(first_icon_classes, "fa-chevron-right")
      assert String.contains?(second_icon_classes, "fa-icon")
    end

    test "sidebar folder names are well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/component")

      # test default folder name (properly humanized)
      [{"span", [_], [html]}] =
        query(document, "div[phx-value-path='/storybook/a_folder']>span")
        |> LazyHTML.to_tree()

      assert String.contains?(html, "A Folder")

      # test config folder name
      [{"span", [_], [html]}] =
        query(document, "div[phx-value-path='/storybook/b_folder']>span") |> LazyHTML.to_tree()

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
