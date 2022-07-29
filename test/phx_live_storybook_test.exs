defmodule PhxLiveStorybookTest do
  use ExUnit.Case

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  defmodule NoContentStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule TreeStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule TreeBStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule FlatListStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule EmptyFilesStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
  defmodule EmptyFoldersStorybook, do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)

  describe "storybook_entries/0" do
    test "when no content path set it should return no entries" do
      assert NoContentStorybook.storybook_entries() == []
    end

    test "with a flat list of entries, it should return a flat list of 2 components" do
      assert FlatListStorybook.storybook_entries() == [
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: content_path("flat_list/a_component.ex"),
                 relative_path: "/a_component"
               },
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: content_path("flat_list/b_component.ex"),
                 relative_path: "/b_component"
               }
             ]
    end

    test "with a tree hierarchy of contents it should return a hierarchy of components, correctly sorted" do
      assert TreeStorybook.storybook_entries() == [
               %PhxLiveStorybook.PageEntry{
                 module_name: "APage",
                 module: Elixir.TreeStorybook.APage,
                 name: "A Page",
                 path: content_path("tree/a_page.ex"),
                 relative_path: "/a_page"
               },
               %PhxLiveStorybook.PageEntry{
                 module_name: "BPage",
                 module: Elixir.TreeStorybook.BPage,
                 name: "B Page",
                 path: content_path("tree/b_page.ex"),
                 relative_path: "/b_page"
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: content_path("tree/a_component.ex"),
                 relative_path: "/a_component"
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: content_path("tree/b_component.ex"),
                 relative_path: "/b_component"
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "a_folder",
                 relative_path: "/a_folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AFolder.AaComponent,
                     module_name: "AaComponent",
                     name: "Aa Component",
                     path: content_path("tree/a_folder/aa_component.ex"),
                     relative_path: "/a_folder/aa_component"
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AFolder.AbComponent,
                     module_name: "AbComponent",
                     name: "Ab Component",
                     path: content_path("tree/a_folder/ab_component.ex"),
                     relative_path: "/a_folder/ab_component"
                   }
                 ]
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "b_folder",
                 relative_path: "/b_folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BFolder.BaComponent,
                     module_name: "BaComponent",
                     name: "Ba Component",
                     path: content_path("tree/b_folder/ba_component.ex"),
                     relative_path: "/b_folder/ba_component"
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BFolder.BbComponent,
                     module_name: "BbComponent",
                     name: "Bb Component",
                     path: content_path("tree/b_folder/bb_component.ex"),
                     relative_path: "/b_folder/bb_component"
                   }
                 ]
               }
             ]
    end

    test "with an empty folder it should return no entries" do
      assert EmptyFilesStorybook.storybook_entries() == []
    end

    test "with empty sub-folders, it should return a flat list of 2 folders" do
      assert EmptyFoldersStorybook.storybook_entries() == [
               %FolderEntry{name: "empty_a", sub_entries: [], relative_path: "/empty_a"},
               %FolderEntry{name: "empty_b", sub_entries: [], relative_path: "/empty_b"}
             ]
    end
  end

  describe "render_variation/2" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}

    test "it should return HEEX for each component/variation couple" do
      assert TreeStorybook.render_variation(AComponent, :hello) |> rendered_to_string() ==
               "<span data-index=\"42\">a component: hello</span>"

      assert TreeStorybook.render_variation(AComponent, :world) |> rendered_to_string() ==
               "<span data-index=\"37\">a component: world</span>"

      # I did not manage to assert against the HTML
      assert [%Phoenix.LiveView.Component{id: "b_component-hello"}] =
               TreeStorybook.render_variation(BComponent, :hello).dynamic.([])

      assert [%Phoenix.LiveView.Component{id: "b_component-world"}] =
               TreeStorybook.render_variation(BComponent, :world).dynamic.([])
    end
  end

  describe "render_code/2" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}

    test "it should return HEEX for each component/variation couple" do
      assert TreeStorybook.render_code(AComponent, :hello) |> rendered_to_string() =~
               ~r/<pre.*pre/

      assert TreeStorybook.render_code(AComponent, :world) |> rendered_to_string() =~
               ~r/<pre.*pre/

      assigns = []

      code = TreeStorybook.render_code(BComponent, :hello)
      assert rendered_to_string(~H"<div><%= code %></div>") =~ ~r/<pre.*pre/

      code = TreeStorybook.render_code(BComponent, :world)
      assert rendered_to_string(~H"<div><%= code %></div>") =~ ~r/<pre.*pre/
    end
  end

  describe "render_source/1" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}

    test "it should return HEEX for each component" do
      assert TreeStorybook.render_source(AComponent) |> rendered_to_string() =~
               ~r/<pre.*Phoenix\.Component.*<\/pre>/s

      assert TreeStorybook.render_source(BComponent) |> rendered_to_string() =~
               ~r/<pre.*Phoenix\.LiveComponent.*<\/pre>/s
    end
  end

  describe "path_to_first_leaf_entry/0" do
    test "with a tree it should return path to first component" do
      assert TreeBStorybook.path_to_first_leaf_entry() == [
               "b_folder",
               "bb_folder",
               "bba_component"
             ]
    end

    test "with empty folder" do
      assert NoContentStorybook.path_to_first_leaf_entry() == nil
    end

    test "with empty sub folders" do
      assert EmptyFoldersStorybook.path_to_first_leaf_entry() == nil
    end
  end

  defp content_path(relative_path) do
    ["fixtures", "storybook_content", relative_path] |> Path.join() |> Path.expand(__DIR__)
  end
end
