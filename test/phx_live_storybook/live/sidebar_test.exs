defmodule PhxLiveStorybook.SidebarTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Floki, only: [find: 2]

  alias PhxLiveStorybook.Sidebar

  describe "storybook with flat list of entries" do
    defmodule FlatListStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "sidebar contains those 2 entries" do
      {document, _html} = render_sidebar(FlatListStorybook)
      # test sidebar has 2 entries
      assert find(document, "nav>ul>li") |> length() == 2

      # test those 2 entries are links (ie. not folders)
      assert find(document, "nav>ul>li>div>a") |> length() == 2
    end
  end

  describe "storybook with a tree of entries" do
    defmodule TreeStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "sidebar contains all entries, with one open folder" do
      {document, _html} = render_sidebar(TreeStorybook)

      # test sidebar has 4 entries
      assert find(document, "nav>ul>li") |> length() == 4

      # test 2 of them are links (ie. not folders)
      assert find(document, "nav>ul>li>div>a") |> length() == 2

      # third node (which is 1st folder) is closed
      assert find(document, "nav>ul>li:nth-child(3)>ul>li") |> length() == 0

      # fourth node (which is 2nd folder) is open (by config)
      assert find(document, "nav>ul>li:nth-child(4)>ul>li") |> length() == 2
    end

    test "sidebar with a path contains all entries, with 2 open folders" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test sidebar has 4 entries
      assert find(document, "nav>ul>li") |> length() == 4

      # test 2 of them are links (ie. not folders)
      assert find(document, "nav>ul>li>div>a") |> length() == 2

      # third node (which is 1st folder) is open (by path)
      assert find(document, "nav>ul>li:nth-child(3)>ul>li") |> length() == 2

      # fourth node (which is 2nd folder) is open (by config)
      assert find(document, "nav>ul>li:nth-child(4)>ul>li") |> length() == 2
    end

    test "sidebar with a path has active entry marked as active" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test 1th entry in 1st folder is active (font-bold class)
      [{"div", [{"class", link_class} | _], _}] =
        find(document, "nav>ul>li:nth-child(3)>ul>li:nth-child(1)>div")

      assert String.contains?(link_class, "lsb-font-bold")
    end

    test "sidebar with an icon folder is well displayed" do
      {document, _html} = render_sidebar(TreeStorybook, "a_folder/aa_component")

      # test 1st folder has 2 icons
      [
        {"i", [{"class", first_icon_classes} | _], _},
        {"i", [{"class", second_icon_classes} | _], _}
      ] = find(document, "nav>ul>li:nth-child(3)>div>i")

      assert String.contains?(first_icon_classes, "fa-caret-down")
      assert String.contains?(second_icon_classes, "fa-icon")
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
