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
                 absolute_path: "/a_component",
                 variations: []
               },
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.BComponent,
                 module_name: "BComponent",
                 type: :live_component,
                 name: "B Component",
                 path: content_path("flat_list/b_component.exs"),
                 absolute_path: "/b_component",
                 variations: []
               }
             ]
    end

    test "with a tree hierarchy of contents it should return a hierarchy of components, correctly sorted" do
      assert TreeStorybook.entries() == [
               %PhxLiveStorybook.PageEntry{
                 module_name: "APage",
                 module: Elixir.TreeStorybook.APage,
                 name: "A Page",
                 description: "a page",
                 path: content_path("tree/a_page.exs"),
                 absolute_path: "/a_page",
                 icon: "fa fa-page",
                 navigation: []
               },
               %PhxLiveStorybook.PageEntry{
                 module_name: "BPage",
                 module: Elixir.TreeStorybook.BPage,
                 name: "B Page",
                 description: "b page",
                 path: content_path("tree/b_page.exs"),
                 absolute_path: "/b_page",
                 icon: "fa fa-page",
                 navigation: [{:tab_1, "Tab 1", ""}, {:tab_2, "Tab 2", ""}]
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.AComponent,
                 module_name: "AComponent",
                 type: :component,
                 function: &AComponent.a_component/1,
                 name: "A Component",
                 description: "a component description",
                 path: content_path("tree/a_component.exs"),
                 absolute_path: "/a_component",
                 variations: [
                   %PhxLiveStorybook.Variation{
                     attributes: %{label: "hello"},
                     description: "Hello variation",
                     id: :hello
                   },
                   %PhxLiveStorybook.Variation{
                     attributes: %{index: 37, label: "world"},
                     description: "World variation",
                     id: :world
                   }
                 ]
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 type: :live_component,
                 component: BComponent,
                 description: "b component description",
                 path: content_path("tree/b_component.exs"),
                 absolute_path: "/b_component",
                 variations: [
                   %PhxLiveStorybook.Variation{
                     attributes: %{label: "hello"},
                     description: "Hello variation",
                     id: :hello
                   },
                   %PhxLiveStorybook.Variation{
                     attributes: %{label: "world"},
                     block: "<span>inner block</span>\n",
                     id: :world
                   }
                 ]
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "a_folder",
                 absolute_path: "/a_folder",
                 icon: "fa-icon",
                 nice_name: "A folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AFolder.AaComponent,
                     function: &AComponent.a_component/1,
                     module_name: "AaComponent",
                     name: "Aa Component",
                     type: :component,
                     description: "Aa component description",
                     path: content_path("tree/a_folder/aa_component.exs"),
                     absolute_path: "/a_folder/aa_component",
                     icon: "aa-icon",
                     variations: [
                       %PhxLiveStorybook.VariationGroup{
                         id: :group,
                         variations: [
                           %PhxLiveStorybook.Variation{
                             attributes: %{label: "hello"},
                             description: "Hello variation",
                             id: :hello
                           },
                           %PhxLiveStorybook.Variation{
                             attributes: %{index: 37, label: "world"},
                             description: "World variation",
                             id: :world
                           }
                         ]
                       }
                     ]
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AFolder.AbComponent,
                     module_name: "AbComponent",
                     name: "Ab Component",
                     component: BComponent,
                     type: :live_component,
                     description: "Ab component description",
                     path: content_path("tree/a_folder/ab_component.exs"),
                     absolute_path: "/a_folder/ab_component",
                     variations: [
                       %PhxLiveStorybook.VariationGroup{
                         id: :group,
                         variations: [
                           %PhxLiveStorybook.Variation{
                             attributes: %{label: "hello"},
                             description: "Hello variation",
                             id: :hello
                           },
                           %PhxLiveStorybook.Variation{
                             attributes: %{label: "world"},
                             block: "<span>inner block</span>\n",
                             id: :world
                           }
                         ]
                       }
                     ]
                   }
                 ]
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "b_folder",
                 absolute_path: "/b_folder",
                 nice_name: "Config Name",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BFolder.BaComponent,
                     module_name: "BaComponent",
                     name: "Ba Component",
                     type: :component,
                     description: "Ba component description",
                     path: content_path("tree/b_folder/ba_component.exs"),
                     absolute_path: "/b_folder/ba_component",
                     variations: []
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BFolder.BbComponent,
                     module_name: "BbComponent",
                     name: "Bb Component",
                     type: :component,
                     description: "Bb component description",
                     path: content_path("tree/b_folder/bb_component.exs"),
                     absolute_path: "/b_folder/bb_component",
                     variations: []
                   }
                 ]
               }
             ]
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
                 absolute_path: "/empty_a"
               },
               %FolderEntry{
                 name: "empty_b",
                 nice_name: "Empty b",
                 sub_entries: [],
                 absolute_path: "/empty_b"
               }
             ]
    end
  end

  describe "render_variation/2" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}
    alias Elixir.TreeStorybook.AFolder.{AaComponent, AbComponent}

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

    test "it also works for a variation group" do
      assert TreeStorybook.render_variation(AaComponent, :group) |> rendered_to_string() ==
               "<span data-index=\"42\">a component: hello</span>\n<span data-index=\"37\">a component: world</span>"

      # I did not manage to assert against the HTML
      assert [
               %Phoenix.LiveView.Component{id: "ab_component-group-hello"},
               %Phoenix.LiveView.Component{id: "ab_component-group-world"}
             ] = TreeStorybook.render_variation(AbComponent, :group).dynamic.([])
    end
  end

  describe "render_code/2" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}
    alias Elixir.TreeStorybook.AFolder.{AaComponent, AbComponent}

    test "it should return HEEX for each component/variation couple" do
      assert TreeStorybook.render_code(AComponent, :hello)
             |> rendered_to_string() =~ ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(AComponent, :world)
             |> rendered_to_string() =~ ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(BComponent, :hello) |> rendered_to_string() =~
               ~r|<pre.*</pre>|s

      assert TreeStorybook.render_code(BComponent, :world) |> rendered_to_string() =~
               ~r|<pre.*</pre>|s
    end

    test "it also works for a variation group" do
      assigns = []
      code = TreeStorybook.render_code(AaComponent, :group)
      assert rendered_to_string(~H"<div><%= code %></div>") =~ ~r/<pre.*pre/

      code = TreeStorybook.render_code(AbComponent, :group)
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

  describe "all_leaves/0" do
    test "with a tree it should return all leaves" do
      assert TreeBStorybook.all_leaves() == [
               %ComponentEntry{
                 absolute_path: "/b_folder/bb_folder/b_ba_component",
                 module: Elixir.TreeBStorybook.BFolder.BBFolder.BBaComponent,
                 type: :component,
                 module_name: "BBaComponent",
                 name: "B Ba Component",
                 path: content_path("tree_b/b_folder/bb_folder/bba_component.exs"),
                 variations: []
               },
               %ComponentEntry{
                 absolute_path: "/b_folder/bb_folder/bbb_component",
                 module: Elixir.TreeBStorybook.BFolder.BbFolder.BbbComponent,
                 type: :component,
                 module_name: "BbbComponent",
                 name: "Bbb Component",
                 path: content_path("tree_b/b_folder/bb_folder/bbb_component.exs"),
                 variations: []
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

  defp content_path(absolute_path) do
    ["fixtures", "storybook_content", absolute_path] |> Path.join() |> Path.expand(__DIR__)
  end
end
