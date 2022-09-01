defmodule PhxLiveStorybookTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  alias PhxLiveStorybook.{
    EmptyFilesStorybook,
    EmptyFoldersStorybook,
    FlatListStorybook,
    NoContentStorybook,
    TreeStorybook,
    TreeBStorybook
  }

  describe "entries/0" do
    test "when no content path set it should return no entries" do
      assert NoContentStorybook.entries() == []
    end

    test "with a flat list of entries, it should return a flat list of 2 components" do
      assert FlatListStorybook.entries() == [
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.AComponent,
                 module_name: "AComponent",
                 type: :component,
                 name: "A Component",
                 path: content_path("flat_list/a_component.exs"),
                 storybook_path: "/a_component",
                 container: :div,
                 attributes: [],
                 stories: []
               },
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.BComponent,
                 module_name: "BComponent",
                 type: :live_component,
                 name: "B Component",
                 path: content_path("flat_list/b_component.exs"),
                 storybook_path: "/b_component",
                 container: :div,
                 attributes: [],
                 stories: []
               }
             ]
    end

    test "with a tree hierarchy of contents it should return a hierarchy of components, correctly sorted" do
      entries = TreeStorybook.entries()
      assert Enum.count(entries) == 7

      assert %PhxLiveStorybook.PageEntry{
               module_name: "APage",
               module: Elixir.TreeStorybook.APage,
               name: "A Page",
               description: "a page",
               storybook_path: "/a_page",
               icon: "fa fa-page",
               navigation: []
             } = Enum.at(entries, 0)

      assert %PhxLiveStorybook.PageEntry{
               module_name: "BPage",
               module: Elixir.TreeStorybook.BPage,
               name: "B Page",
               description: "b page",
               storybook_path: "/b_page",
               navigation: [{:tab_1, "Tab 1", ""}, {:tab_2, "Tab 2", ""}]
             } = Enum.at(entries, 1)

      assert %PhxLiveStorybook.ComponentEntry{
               module: Elixir.TreeStorybook.Component,
               module_name: "Component",
               type: :component,
               name: "Component",
               description: "component description",
               storybook_path: "/component",
               attributes: [
                 %PhxLiveStorybook.Attr{
                   id: :label,
                   required: true,
                   type: :string,
                   doc: "component label"
                 }
               ],
               stories: [
                 %PhxLiveStorybook.Story{
                   attributes: %{label: "hello"},
                   description: "Hello story",
                   id: :hello
                 },
                 %PhxLiveStorybook.Story{
                   attributes: %{index: 37, label: "world"},
                   description: "World story",
                   id: :world
                 }
               ]
             } = Enum.at(entries, 2)

      assert %PhxLiveStorybook.ComponentEntry{
               module: Elixir.TreeStorybook.LiveComponent,
               module_name: "LiveComponent",
               name: "Live Component (root)",
               type: :live_component,
               component: LiveComponent,
               description: "live component description",
               storybook_path: "/live_component",
               stories: [
                 %PhxLiveStorybook.Story{
                   attributes: %{label: "hello"},
                   description: "Hello story",
                   id: :hello
                 },
                 %PhxLiveStorybook.Story{
                   attributes: %{label: "world"},
                   block: "<span>inner block</span>\n",
                   id: :world
                 }
               ]
             } = Enum.at(entries, 3)

      assert %PhxLiveStorybook.FolderEntry{
               name: "a_folder",
               storybook_path: "/a_folder",
               icon: "fa-icon",
               nice_name: "A folder",
               sub_entries: [
                 %PhxLiveStorybook.ComponentEntry{
                   module: Elixir.TreeStorybook.AFolder.Component
                 },
                 %PhxLiveStorybook.ComponentEntry{
                   module: Elixir.TreeStorybook.AFolder.LiveComponent
                 }
               ]
             } = Enum.at(entries, 4)

      assert %PhxLiveStorybook.FolderEntry{
               name: "b_folder",
               storybook_path: "/b_folder",
               nice_name: "Config Name",
               sub_entries: [
                 %PhxLiveStorybook.ComponentEntry{
                   module: Elixir.TreeStorybook.BFolder.AllTypesComponent
                 },
                 %PhxLiveStorybook.ComponentEntry{
                   module: Elixir.TreeStorybook.BFolder.Component
                 }
               ]
             } = Enum.at(entries, 5)
    end

    test "with an empty folder it should return no entries" do
      assert EmptyFilesStorybook.entries() == []
    end

    test "with empty sub-folders, it should return a flat list of 2 folders" do
      assert EmptyFoldersStorybook.entries() == [
               %FolderEntry{
                 name: "empty_a",
                 nice_name: "Empty a",
                 sub_entries: [],
                 storybook_path: "/empty_a"
               },
               %FolderEntry{
                 name: "empty_b",
                 nice_name: "Empty b",
                 sub_entries: [],
                 storybook_path: "/empty_b"
               }
             ]
    end
  end

  describe "render_story/2" do
    alias Elixir.TreeStorybook.{Component, LiveComponent}

    test "it should return HEEX for each component/story couple" do
      assert TreeStorybook.render_story(Component, :hello) |> rendered_to_string() ==
               "<span data-index=\"42\">component: hello</span>"

      assert TreeStorybook.render_story(Component, :world) |> rendered_to_string() ==
               "<span data-index=\"37\">component: world</span>"

      # I did not manage to assert against the HTML
      assert [%Phoenix.LiveView.Component{id: "live_component-hello"}] =
               TreeStorybook.render_story(LiveComponent, :hello).dynamic.([])

      assert [%Phoenix.LiveView.Component{id: "live_component-world"}] =
               TreeStorybook.render_story(LiveComponent, :world).dynamic.([])
    end

    test "it also works for a story group" do
      assert TreeStorybook.render_story(Elixir.TreeStorybook.AFolder.Component, :group)
             |> rendered_to_string() ==
               "<span data-index=\"42\">component: hello</span>\n<span data-index=\"37\">component: world</span>"

      # I did not manage to assert against the HTML
      assert [
               %Phoenix.LiveView.Component{id: "live_component-group-hello"},
               %Phoenix.LiveView.Component{id: "live_component-group-world"}
             ] =
               TreeStorybook.render_story(Elixir.TreeStorybook.AFolder.LiveComponent, :group).dynamic.(
                 []
               )
    end

    test "it raises a compile error if component rendering raises" do
      assert_raise CompileError, ~r/an error occured while rendering story story/, fn ->
        defmodule Elixir.PhxLiveStorybook.RenderComponentCrashStorybook,
          do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
      end
    end
  end

  describe "render_code/2" do
    test "it should return HEEX for each component/story couple" do
      assert TreeStorybook.render_code(Elixir.TreeStorybook.Component, :hello)
             |> rendered_to_string() =~ ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(Elixir.TreeStorybook.Component, :world)
             |> rendered_to_string() =~ ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(Elixir.TreeStorybook.LiveComponent, :hello)
             |> rendered_to_string() =~
               ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(Elixir.TreeStorybook.LiveComponent, :world)
             |> rendered_to_string() =~
               ~r|<pre.*</pre>|s
    end

    test "it also works for a story group" do
      assigns = []
      code = TreeStorybook.render_code(Elixir.TreeStorybook.AFolder.Component, :group)
      assert rendered_to_string(~H"<div><%= code %></div>") =~ ~r/<pre.*pre/

      code = TreeStorybook.render_code(Elixir.TreeStorybook.AFolder.LiveComponent, :group)
      assert rendered_to_string(~H"<div><%= code %></div>") =~ ~r/<pre.*pre/
    end
  end

  describe "render_page/1" do
    alias Elixir.TreeStorybook.APage

    test "it should return HEEX for the page" do
      assert TreeStorybook.render_page(APage, nil) |> rendered_to_string() =~
               "<span>A Page</span>"
    end

    test "it raises a compile error if a page rendering raises" do
      assert_raise CompileError, ~r/an error occured while rendering page/, fn ->
        defmodule Elixir.PhxLiveStorybook.RenderPageCrashStorybook,
          do: use(PhxLiveStorybook, otp_app: :phx_live_storybook)
      end
    end
  end

  describe "render_source/1" do
    alias Elixir.TreeStorybook.{Component, LiveComponent}

    test "it should return HEEX for each component" do
      assert TreeStorybook.render_source(Component) |> rendered_to_string() =~
               ~r/<pre.*Phoenix\.Component.*<\/pre>/s

      assert TreeStorybook.render_source(LiveComponent) |> rendered_to_string() =~
               ~r/<pre.*Phoenix\.LiveComponent.*<\/pre>/s
    end
  end

  describe "all_leaves/0" do
    test "with a tree it should return all leaves" do
      assert TreeBStorybook.all_leaves() == [
               %ComponentEntry{
                 storybook_path: "/b_folder/bb_folder/b_ba_component",
                 module: Elixir.TreeBStorybook.BFolder.BBFolder.BBaComponent,
                 type: :component,
                 module_name: "BBaComponent",
                 name: "B Ba Component",
                 path: content_path("tree_b/b_folder/bb_folder/bba_component.exs"),
                 container: :div,
                 attributes: [],
                 stories: []
               },
               %ComponentEntry{
                 storybook_path: "/b_folder/bb_folder/bbb_component",
                 module: Elixir.TreeBStorybook.BFolder.BbFolder.BbbComponent,
                 type: :component,
                 module_name: "BbbComponent",
                 name: "Bbb Component",
                 path: content_path("tree_b/b_folder/bb_folder/bbb_component.exs"),
                 container: :div,
                 attributes: [],
                 stories: []
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

  defp content_path(storybook_path) do
    ["fixtures", "storybook_content", storybook_path] |> Path.join() |> Path.expand(__DIR__)
  end
end
