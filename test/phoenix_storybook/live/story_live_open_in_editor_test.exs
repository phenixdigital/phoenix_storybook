defmodule PhoenixStorybook.StoryLiveOpenInEditorTest do
  # async: false — these tests mutate the process-global PLUG_EDITOR env var.
  use ExUnit.Case, async: false

  @endpoint PhoenixStorybook.StoryLiveTestEndpoint
  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  use Phoenix.VerifiedRoutes, endpoint: @endpoint, router: PhoenixStorybook.TestRouter

  @editor "vscode://file/__FILE__:__LINE__"

  setup_all do
    case start_supervised(@endpoint) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    {:ok, conn: build_conn()}
  end

  setup do
    System.delete_env("PLUG_EDITOR")
    on_exit(fn -> System.delete_env("PLUG_EDITOR") end)
  end

  test "renders open-in-editor button pointing at the example source file", %{conn: conn} do
    System.put_env("PLUG_EDITOR", @editor)

    {:ok, view, _html} = live(conn, ~p"/storybook/examples/example")
    view |> element("a", "Source") |> render_click()

    assert has_element?(
             view,
             "a[title='Open in editor'][href^='vscode://file/']" <>
               "[href$='/examples/example.story.exs:1'] i.fa-solid.fa-file-code"
           )
  end

  test "uses the component module path and function line for component stories", %{conn: conn} do
    System.put_env("PLUG_EDITOR", @editor)

    {:ok, view, _html} = live(conn, ~p"/storybook/a_folder/component")
    html = view |> element("a", "Source") |> render_click()

    [_, href] = Regex.run(~r/href="(vscode:\/\/file\/[^"]+)"/, html)
    assert href =~ ~r|/component\.ex:4$|
  end

  test "updates the editor path when selecting an extra source", %{conn: conn} do
    System.put_env("PLUG_EDITOR", @editor)

    {:ok, view, _html} = live(conn, ~p"/storybook/examples/example")
    view |> element("a", "Source") |> render_click()

    view
    |> element("form[id$='-source-selection-form'] select")
    |> render_change(%{source: %{file: "./templates/example.html.heex"}})

    assert has_element?(
             view,
             "a[title='Open in editor'][href$='/examples/templates/example.html.heex:1']"
           )
  end

  test "does not render open-in-editor button when PLUG_EDITOR is unset", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/storybook/examples/example")
    view |> element("a", "Source") |> render_click()

    refute has_element?(view, "a[title='Open in editor']")
  end
end
