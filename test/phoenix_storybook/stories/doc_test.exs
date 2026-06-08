defmodule PhoenixStorybook.Stories.DocTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias PhoenixStorybook.ExsCompiler
  alias PhoenixStorybook.Stories.Doc

  describe "fetch_doc_as_html/2" do
    test "it returns a function component documentation" do
      assert %Doc{header: header, body: body} =
               "component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html()

      assert header == "<p>Component first doc paragraph.\nStill first paragraph.</p>"
      assert body =~ "<p>Second paragraph.</p>"
      assert body =~ "<h2>Examples</h2>"
      assert body =~ ~s[<span class="nf">.component</span>]
      assert body =~ ~s[<span class="nc">Component</span>]
      assert body =~ ~s[<span class="ss">:cool</span>]
      assert body =~ ~s[data-group-id=]
      assert body =~ ~s[<span class="ss">:boring</span>]
    end

    test "it returns a live component documentation" do
      assert %Doc{header: header, body: body} =
               "live_component.story.exs" |> compile_story() |> Doc.fetch_doc_as_html()

      assert header == "<p>LiveComponent first doc paragraph.\nStill first paragraph.</p>"
      assert body == "<p>Second paragraph.</p>"
    end

    test "returns no body for a single line documentation" do
      assert %Doc{header: header, body: nil} =
               "b_folder/all_types_component.story.exs"
               |> compile_story()
               |> Doc.fetch_doc_as_html()

      assert header == "<p>Component mixing any attribute possible types.</p>"
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

    test "it does not crash with css and untyped code blocks" do
      %Doc{header: header, body: body} =
        "event/event_component.story.exs"
        |> compile_story()
        |> Doc.fetch_doc_as_html()

      refute is_nil(header)
      refute is_nil(body)
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
