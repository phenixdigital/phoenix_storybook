defmodule PhxLiveStorybookTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.{ComponentStory, Folder}

  alias PhxLiveStorybook.{
    EmptyFilesStorybook,
    EmptyFoldersStorybook,
    FlatListStorybook,
    NoContentStorybook,
    TreeStorybook,
    TreeBStorybook
  }

  describe "stories/0" do
    test "when no content path set it should return no stories" do
      assert NoContentStorybook.stories() == []
    end

    test "with a flat list of stories, it should return a flat list of 2 components" do
      assert FlatListStorybook.stories() == [
               %ComponentStory{
                 module: Elixir.FlatListStorybook.AComponent,
                 name: "A Component",
                 storybook_path: "/a_component"
               },
               %ComponentStory{
                 module: Elixir.FlatListStorybook.BComponent,
                 name: "B Component",
                 storybook_path: "/b_component"
               }
             ]
    end

    test "with a tree hierarchy of contents it should return a hierarchy of components, correctly sorted" do
      stories = TreeStorybook.stories()
      assert Enum.count(stories) == 9

      assert %PhxLiveStorybook.PageStory{
               module_name: "APage",
               module: Elixir.TreeStorybook.APage,
               name: "A Page",
               description: "a page",
               storybook_path: "/a_page",
               icon: "fa fa-page",
               navigation: []
             } = Enum.at(stories, 0)

      assert %PhxLiveStorybook.PageStory{
               module_name: "BPage",
               module: Elixir.TreeStorybook.BPage,
               name: "B Page",
               description: "b page",
               storybook_path: "/b_page",
               navigation: [{:tab_1, "Tab 1", ""}, {:tab_2, "Tab 2", ""}]
             } = Enum.at(stories, 1)

      assert %PhxLiveStorybook.ComponentStory{
               module: Elixir.TreeStorybook.Component,
               name: "Component",
               description: "component description",
               storybook_path: "/component"
             } = Enum.at(stories, 2)

      assert %PhxLiveStorybook.ComponentStory{
               module: Elixir.TreeStorybook.LiveComponent,
               name: "Live Component (root)",
               description: "live component description",
               storybook_path: "/live_component"
             } = Enum.at(stories, 3)

      assert %PhxLiveStorybook.Folder{
               name: "a_folder",
               storybook_path: "/a_folder",
               icon: "fa-icon",
               nice_name: "A folder",
               items: [
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.AFolder.Component
                 },
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.AFolder.LiveComponent
                 }
               ]
             } = Enum.at(stories, 4)

      assert %PhxLiveStorybook.Folder{
               name: "b_folder",
               storybook_path: "/b_folder",
               nice_name: "Config Name",
               items: [
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.BFolder.AllTypesComponent
                 },
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.BFolder.Component
                 },
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.BFolder.NestedComponent
                 }
               ]
             } = Enum.at(stories, 5)

      assert %PhxLiveStorybook.Folder{
               name: "event",
               storybook_path: "/event",
               nice_name: "Event",
               items: [
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.Event.EventComponent
                 },
                 %PhxLiveStorybook.ComponentStory{
                   module: Elixir.TreeStorybook.Event.EventLiveComponent
                 }
               ]
             } = Enum.at(stories, 6)
    end

    test "with an empty folder it should return no stories" do
      assert EmptyFilesStorybook.stories() == []
    end

    test "with empty sub-folders, it should return a flat list of 2 folders" do
      assert EmptyFoldersStorybook.stories() == [
               %Folder{
                 name: "empty_a",
                 nice_name: "Empty a",
                 items: [],
                 storybook_path: "/empty_a"
               },
               %Folder{
                 name: "empty_b",
                 nice_name: "Empty b",
                 items: [],
                 storybook_path: "/empty_b"
               }
             ]
    end
  end

  describe "all_leaves/0" do
    test "with a tree it should return all leaves" do
      assert TreeBStorybook.all_leaves() == [
               %ComponentStory{
                 storybook_path: "/b_folder/bb_folder/b_ba_component",
                 module: Elixir.TreeBStorybook.BFolder.BBFolder.BBaComponent,
                 name: "B Ba Component"
               },
               %ComponentStory{
                 storybook_path: "/b_folder/bb_folder/bbb_component",
                 module: Elixir.TreeBStorybook.BFolder.BbFolder.BbbComponent,
                 name: "Bbb Component"
               }
             ]
    end

    test "with empty folder" do
      assert NoContentStorybook.all_leaves() == []
    end

    test "with empty sub folders" do
      assert EmptyFoldersStorybook.all_leaves() == []
    end
  end
end
