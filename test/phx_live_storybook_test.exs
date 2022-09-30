defmodule PhxLiveStorybookTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.{FolderEntry, StoryEntry}

  alias PhxLiveStorybook.{
    EmptyFilesStorybook,
    EmptyFoldersStorybook,
    FlatListStorybook,
    TreeStorybook,
    TreeBStorybook
  }

  describe "stories/0" do
    test "when no content path set it should raise" do
      assert_raise RuntimeError, "content_path key must be set", fn ->
        defmodule PhxLiveStorybook.NoContentStorybook do
          use Elixir.PhxLiveStorybook, otp_app: :phx_live_storybook
        end
      end
    end

    test "with a flat list of stories, it should return a flat list of 2 components" do
      assert FlatListStorybook.content_tree() == [
               %FolderEntry{
                 name: "Storybook",
                 icon: {:fa, "book-open", :light, "lsb-mr-1"},
                 path: "",
                 entries: [
                   %StoryEntry{
                     name: "A Component",
                     path: "/a_component"
                   },
                   %StoryEntry{
                     name: "B Component",
                     path: "/b_component"
                   }
                 ]
               }
             ]
    end

    test "with a tree hierarchy of contents it should return a hierarchy of components, correctly sorted" do
      [%FolderEntry{entries: entries}] = TreeStorybook.content_tree()
      assert Enum.count(entries) == 9

      assert %StoryEntry{name: "A Page", path: "/a_page", icon: {:fa, "page"}} =
               Enum.at(entries, 0)

      assert %StoryEntry{name: "B Page", path: "/b_page"} = Enum.at(entries, 1)
      assert %StoryEntry{name: "Component", path: "/component"} = Enum.at(entries, 2)

      assert %StoryEntry{name: "Live Component (root)", path: "/live_component"} =
               Enum.at(entries, 3)

      assert %FolderEntry{
               path: "/a_folder",
               icon: {:fa, "icon"},
               name: "A Folder",
               entries: [%StoryEntry{}, %StoryEntry{}]
             } = Enum.at(entries, 4)

      assert %FolderEntry{
               path: "/b_folder",
               name: "Config Name",
               entries: [%StoryEntry{}, %StoryEntry{}, %StoryEntry{}, %StoryEntry{}]
             } = Enum.at(entries, 5)

      assert %FolderEntry{
               path: "/event",
               name: "Event",
               entries: [%StoryEntry{}, %StoryEntry{}]
             } = Enum.at(entries, 6)
    end

    test "with an empty folder it should return no stories" do
      assert EmptyFilesStorybook.content_tree() == [
               %FolderEntry{
                 entries: [],
                 icon: {:fa, "book-open", :light, "lsb-mr-1"},
                 name: "Storybook",
                 path: ""
               }
             ]
    end

    test "with empty sub-folders, it should return a flat list of 2 folders" do
      [%FolderEntry{entries: entries}] = EmptyFoldersStorybook.content_tree()

      assert entries == [
               %FolderEntry{
                 name: "Empty a",
                 entries: [],
                 path: "/empty_a"
               },
               %FolderEntry{
                 name: "Empty b",
                 entries: [],
                 path: "/empty_b"
               }
             ]
    end
  end

  describe "leaves/0" do
    test "with a tree it should return all leaves" do
      assert TreeBStorybook.leaves() == [
               %StoryEntry{
                 path: "/b_folder/bb_folder/b_ba_component",
                 name: "B Ba Component"
               },
               %StoryEntry{
                 path: "/b_folder/bb_folder/b_bb_component",
                 name: "B Bb Component"
               }
             ]
    end

    test "with empty sub folders" do
      assert EmptyFoldersStorybook.leaves() == []
    end
  end

  describe "load_story/1 & story_path/1" do
    test "it returns the path when the module is loaded" do
      path = "/a_folder/component"
      {:ok, module} = TreeStorybook.load_story(path)
      assert TreeStorybook.storybook_path(module) == path
    end
  end
end
