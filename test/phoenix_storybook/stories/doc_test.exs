defmodule PhoenixStorybook.Stories.DocTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias PhoenixStorybook.ExsCompiler
  alias PhoenixStorybook.Stories.Doc

  describe "fetch_doc_as_html/2" do
    test "it returns a function component documentation" do
      assert "component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html() == [
               "<p>\nComponent first doc paragraph.\nStill first paragraph.</p>",
               "<p>\nSecond paragraph.</p>"
             ]
    end

    test "it returns a live component documentation" do
      assert "live_component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html() == [
               "<p>\nLiveComponent first doc paragraph.\nStill first paragraph.</p>",
               "<p>\nSecond paragraph.</p>"
             ]
    end

    test "it returns nik when there is no doc" do
      assert "let/let_component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html() == nil
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
