defmodule PhxLiveStorybookTest do
  use ExUnit.Case

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  describe "storybook with no content path set" do
    defmodule NoContentStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "entries/1 should return no entries" do
      assert NoContentStorybook.storybook_entries() == []
    end
  end

  describe "storybook with flat list of entries" do
    defmodule FlatListStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "entries/1 should return a flat list of 2 components" do
      assert FlatListStorybook.storybook_entries() == [
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: fixture_path("flat_list_content/a_component.ex")
               },
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: fixture_path("flat_list_content/b_component.ex")
               }
             ]
    end
  end

  describe "storybook with a tree hierarchy of contents" do
    defmodule TreeStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "entries/1 should return a hierarchy of components, correctly sorted" do
      assert TreeStorybook.storybook_entries() == [
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: fixture_path("tree_content/a_component.ex")
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: fixture_path("tree_content/b_component.ex")
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "a_folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AAComponent,
                     module_name: "AAComponent",
                     name: "Aa Component",
                     path: fixture_path("tree_content/a_folder/aa_component.ex")
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.ABComponent,
                     module_name: "ABComponent",
                     name: "Ab Component",
                     path: fixture_path("tree_content/a_folder/ab_component.ex")
                   }
                 ]
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "b_folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BAComponent,
                     module_name: "BAComponent",
                     name: "Ba Component",
                     path: fixture_path("tree_content/b_folder/ba_component.ex")
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BBComponent,
                     module_name: "BBComponent",
                     name: "Bb Component",
                     path: fixture_path("tree_content/b_folder/bb_component.ex")
                   }
                 ]
               }
             ]
    end
  end

  describe "storybook with empty files" do
    defmodule EmptyFilesStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "entries/1 should return no entries" do
      assert EmptyFilesStorybook.storybook_entries() == []
    end
  end

  describe "storybook with empty folders" do
    defmodule EmptyFoldersStorybook do
      # content_path is set in config/config.ex
      use PhxLiveStorybook, otp_app: :phx_live_storybook
    end

    test "entries/1 should return a flat list of 2 folders" do
      assert EmptyFoldersStorybook.storybook_entries() == [
               %FolderEntry{name: "empty_a", sub_entries: []},
               %FolderEntry{name: "empty_b", sub_entries: []}
             ]
    end
  end

  defp fixture_path(relative_path) do
    ["fixtures", relative_path] |> Path.join() |> Path.expand(__DIR__)
  end
end
