defmodule PhxLiveStorybook.SidebarTest do
  use ExUnit.Case, async: false
  import Phoenix.LiveViewTest
  import Floki, only: [find: 2]

  alias PhxLiveStorybook.Sidebar

  defmodule FlatListStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule TreeStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)

  describe "storybook with flat list of entries" do
    test "sidebar contains those 2 entries" do
      {document, _html} = render_sidebar(FlatListStorybook)
      # test sidebar has 1 root entry
      assert find(document, "nav>ul>li") |> length() == 1

      # test sidebar has 2 folders beneath root
      assert find(document, "nav>ul>li>ul>li") |> length() == 2

      # test those 2 entries are links (ie. not folders)
      assert find(document, "nav>ul>li>ul>li>div>a") |> length() == 2
    end
  end

  describe "storybook with a tree of entries" do
    test "sidebar contains all entries, with one open folder" do
      {document, _html} = render_sidebar(TreeStorybook)
      # test sidebar has 1 root entry
      assert find(document, "nav>ul>li") |> length() == 1

      # test sidebar has 6 entries
      assert find(document, "nav>ul>li>ul>li") |> length() == 6

      # test 4 of them are links (ie. not folders)
      assert find(document, "nav>ul>li>ul>li>div>a") |> length() == 4

      # fifth node (which is 1st folder) is closed
      assert find(document, "nav>ul>li>ul>li:nth-child(5)>ul>li") |> length() == 0

      # sixth node (which is 2nd folder) is open (by config)
      assert find(document, "nav>ul>li>ul>li:nth-child(6)>ul>li") |> length() == 2
    end

    test "sidebar with a path contains all entries, with 2 open folders" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")
      # test sidebar has 1 root entry
      assert find(document, "nav>ul>li") |> length() == 1

      # test sidebar has 5 entries
      assert find(document, "nav>ul>li>ul>li") |> length() == 6

      # test 4 of them are links (ie. not folders)
      assert find(document, "nav>ul>li>ul>li>div>a") |> length() == 4

      # fifth node (which is 1st folder) is open (by path)
      assert find(document, "nav>ul>li>ul>li:nth-child(5)>ul>li") |> length() == 2

      # sixth node (which is 2nd folder) is open (by config)
      assert find(document, "nav>ul>li>ul>li:nth-child(6)>ul>li") |> length() == 2
    end

    test "sidebar with a path has active entry marked as active" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test 1th entry in 1st folder is active (font-bold class)
      [{"div", [{"class", link_class} | _], _}] =
        find(document, "nav>ul>li>ul>li:nth-child(5)>ul>li:nth-child(1)>div")

      assert String.contains?(link_class, "lsb-font-bold")
    end

    test "sidebar with an icon folder is well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test 1st folder has 2 icons
      [
        {"i", [{"class", first_icon_classes} | _], _},
        {"i", [{"class", second_icon_classes} | _], _}
      ] = find(document, "nav>ul>li>ul>li:nth-child(5)>div>i")

      assert String.contains?(first_icon_classes, "fa-caret-down")
      assert String.contains?(second_icon_classes, "fa-icon")
    end

    test "sidebar folder names are well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test default folder name (properly humanized)
      [{"span", [_], [html]}] = find(document, "nav>ul>li>ul>li:nth-child(5)>div>span")
      assert String.contains?(html, "A folder")

      # test config folder name
      [{"span", [_], [html]}] = find(document, "nav>ul>li>ul>li:nth-child(6)>div>span")
      assert String.contains?(html, "Config Name")
    end
  end

  defp render_sidebar(backend_module, path \\ "/") do
    html =
      render_component(Sidebar,
        id: "sidebar",
        backend_module: backend_module,
        current_path: String.split(path, "/")
      )

    {:ok, document} = Floki.parse_document(html)
    {document, html}
  end
end
