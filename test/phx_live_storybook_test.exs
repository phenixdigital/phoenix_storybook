defmodule PhxLiveStorybookTest do
  use ExUnit.Case

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

  alias PhxLiveStorybook.{ComponentEntry, FolderEntry}

  defmodule NoContentStorybook do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end

  defmodule TreeStorybook do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end

  defmodule FlatListStorybook do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end

  defmodule EmptyFilesStorybook do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end

  defmodule EmptyFoldersStorybook do
    use PhxLiveStorybook, otp_app: :phx_live_storybook
  end

  describe "storybook_entries/0 when no content path set" do
    test "it should return no entries" do
      assert NoContentStorybook.storybook_entries() == []
    end
  end

  describe "storybook_entries/0 with a flat list of entries" do
    test "it should return a flat list of 2 components" do
      assert FlatListStorybook.storybook_entries() == [
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: content_path("flat_list/a_component.ex")
               },
               %ComponentEntry{
                 module: Elixir.FlatListStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: content_path("flat_list/b_component.ex")
               }
             ]
    end
  end

  describe "storybook_entries/0 with a tree hierarchy of contents" do
    test "it should return a hierarchy of components, correctly sorted" do
      assert TreeStorybook.storybook_entries() == [
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.AComponent,
                 module_name: "AComponent",
                 name: "A Component",
                 path: content_path("tree/a_component.ex")
               },
               %PhxLiveStorybook.ComponentEntry{
                 module: Elixir.TreeStorybook.BComponent,
                 module_name: "BComponent",
                 name: "B Component",
                 path: content_path("tree/b_component.ex")
               },
               %PhxLiveStorybook.FolderEntry{
                 name: "a_folder",
                 sub_entries: [
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.AAComponent,
                     module_name: "AAComponent",
                     name: "Aa Component",
                     path: content_path("tree/a_folder/aa_component.ex")
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.ABComponent,
                     module_name: "ABComponent",
                     name: "Ab Component",
                     path: content_path("tree/a_folder/ab_component.ex")
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
                     path: content_path("tree/b_folder/ba_component.ex")
                   },
                   %PhxLiveStorybook.ComponentEntry{
                     module: Elixir.TreeStorybook.BBComponent,
                     module_name: "BBComponent",
                     name: "Bb Component",
                     path: content_path("tree/b_folder/bb_component.ex")
                   }
                 ]
               }
             ]
    end
  end

  describe "storybook_entries/0 with empty files" do
    test "it should return no entries" do
      assert EmptyFilesStorybook.storybook_entries() == []
    end
  end

  describe "storybook_entries/0 with empty folders" do
    test "it should return a flat list of 2 folders" do
      assert EmptyFoldersStorybook.storybook_entries() == [
               %FolderEntry{name: "empty_a", sub_entries: []},
               %FolderEntry{name: "empty_b", sub_entries: []}
             ]
    end
  end

  describe "render_component/2 with a tree" do
    alias Elixir.TreeStorybook.{AComponent, BComponent}

    test "it should return HEEX for each component/variation couple" do
      assert TreeStorybook.render_component(AComponent, :hello) |> rendered_to_string() ==
               "<span>a component: hello</span>"

      assert TreeStorybook.render_component(AComponent, :world) |> rendered_to_string() ==
               "<span>a component: world</span>"

      # I did not manage to assert against the HTML output
      assert [%Phoenix.LiveView.Component{id: :hello}] =
               TreeStorybook.render_component(BComponent, :hello).dynamic.([])

      assert [%Phoenix.LiveView.Component{id: :world}] =
               TreeStorybook.render_component(BComponent, :world).dynamic.([])
    end
  end

  describe "render_code/2 with a tree" do
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

  defp content_path(relative_path) do
    ["fixtures", "storybook_content", relative_path] |> Path.join() |> Path.expand(__DIR__)
  end
end
