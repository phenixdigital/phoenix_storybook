defmodule PhoenixStorybook.Stories.DocTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias PhoenixStorybook.ExsCompiler
  alias PhoenixStorybook.Stories.Doc

  describe "fetch_doc_as_html/2" do
    test "it returns a function component documentation" do
      assert %Doc{
               header: "<p>\n  Component first doc paragraph.\nStill first paragraph.</p>\n",
               body: "<p>\nSecond paragraph.</p>\n<h2>\nExamples</h2>" <> examples
             } =
               "component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html()

      assert examples =~ ~s[<span class="nf">.component</span>]
      assert examples =~ ~s[<span class="nc">Component</span>]
      assert examples =~ ~s[<span class="ss">:cool</span>]
      assert examples =~ ~s[<span class="ss">:boring</span>]
    end

    test "it returns a live component documentation" do
      assert "live_component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html() == %Doc{
               header: "<p>\n  LiveComponent first doc paragraph.\nStill first paragraph.</p>\n",
               body: "<p>\nSecond paragraph.</p>\n"
             }
    end

    test "returns no body for a single line documentation" do
      assert "b_folder/all_types_component.story.exs"
             |> compile_story()
             |> Doc.fetch_doc_as_html() ==
               %Doc{
                 header: "<p>\n  Component mixing any attribute possible types.</p>\n",
                 body: nil
               }
    end

    test "it returns nil when there is no doc" do
      assert "let/let_live_component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html() ==
               nil
    end

    test "it returns [] when function doc has not yet been compiled" do
      defmodule NoDocComponent do
        use Phoenix.Component
        def no_doc_component(assigns), do: ~H[]
      end

      defmodule NoDocStory do
        use PhoenixStorybook.Story, :component
        def function, do: &NoDocComponent.no_doc_component/1
      end

      log =
        capture_log(fn ->
          assert Doc.fetch_doc_as_html(NoDocStory) == nil
        end)

      assert log =~
               "could not fetch function docs from PhoenixStorybook.Stories.DocTest.NoDocComponent"
    end

    test "it returns [] when live_component doc has not yet been compiled" do
      defmodule NoDocLiveComponent do
        use Phoenix.LiveComponent
        def render(assigns), do: ~H[]
      end

      defmodule NoDocStory do
        use PhoenixStorybook.Story, :live_component
        def component, do: NoDocLiveComponent
      end

      log =
        capture_log(fn ->
          assert Doc.fetch_doc_as_html(NoDocStory) == nil
        end)

      assert log =~
               "could not fetch module doc from PhoenixStorybook.Stories.DocTest.NoDocLiveComponent"
    end
  end

  defp compile_story(path) do
    {:ok, story} =
      ExsCompiler.compile_exs(
        path,
        Path.expand("../../fixtures/storybook_content/tree/", __DIR__)
      )

    story
  end
end
