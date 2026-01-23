defmodule PhoenixStorybook.ComponentIframeLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.Socket
  alias PhoenixStorybook.Stories.{Variation, VariationGroup}
  alias PhoenixStorybook.Story.ComponentIframeLive

  @endpoint PhoenixStorybook.ComponentIframeLiveEndpoint
  @moduletag :capture_log

  defmodule BackendNoTheme do
    def config(_key, default \\ nil), do: default

    def load_story(_story_path), do: {:ok, PhoenixStorybook.ComponentIframeLiveTest.DummyStory}
  end

  defmodule BackendNotFound do
    def config(_key, default \\ nil), do: default
    def load_story(_story_path), do: {:error, :not_found}
  end

  defmodule BackendComponentEmpty do
    def config(_key, default \\ nil), do: default

    def load_story(_story_path),
      do: {:ok, PhoenixStorybook.ComponentIframeLiveTest.EmptyVariationsStory}
  end

  defmodule BackendPage do
    def config(_key, default \\ nil), do: default
    def load_story(_story_path), do: {:ok, PhoenixStorybook.ComponentIframeLiveTest.PageStory}
  end

  defmodule HandleInfoStory do
    def handle_info({:storybook_handle_info, from}, socket) do
      send(from, :handled)
      {:noreply, socket}
    end
  end

  defmodule DummyStory do
    use Phoenix.Component

    def storybook_type, do: :component
    def variations, do: [%Variation{id: :one}]
    def container, do: :div
    def template, do: nil
    def imports, do: []
    def aliases, do: []
    def function, do: &__MODULE__.render/1
    def render(assigns), do: ~H"<div>dummy</div>"
  end

  defmodule EmptyVariationsStory do
    def storybook_type, do: :component
    def variations, do: []
  end

  defmodule PageStory do
    def storybook_type, do: :page
  end

  setup_all do
    start_supervised!(@endpoint)
    {:ok, conn: build_conn()}
  end

  describe "variation rendering" do
    test "it renders a story with a variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "theme" => "default"}
        )

      assert html =~ "component: hello"
    end

    test "it renders a story with a variation group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"variation_id" => "group", "theme" => "colorful"}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "variation with a template", %{conn: conn} do
      {:ok, view, html} =
        live_with_params(conn, "/storybook/iframe/templates/template_iframe_component", %{
          "variation_id" => "hello",
          "theme" => "default"
        })

      assert html =~ "template_component: hello / status: false"

      view |> element("#set-foo-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: foo / status: false"

      view |> element("#set-bar-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#toggle-status-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view |> element("#toggle-status-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: false"

      view |> element("#set-status-true-template-iframe-component-single-hello") |> render_click()
      assert render(view) =~ "template_component: bar / status: true"

      view
      |> element("#set-status-false-template-iframe-component-single-hello")
      |> render_click()

      assert render(view) =~ "template_component: bar / status: false"
    end

    test "it renders an story with a color theme", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "theme" => "default", "color_mode" => "dark"}
        )

      assert html =~ ~r|class="[^"]*dark[^"]*"|
      assert html =~ "component: hello"
    end
  end

  describe "playground" do
    test "it renders a playground with a variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true}
        )

      assert html =~ "component: hello"
    end

    test "it renders a playground with a color_mode", %{conn: conn} do
      {:ok, view, _html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true, "color_mode" => "dark"}
        )

      html = view |> element(".psb-sandbox") |> render()
      [class] = html |> LazyHTML.from_fragment() |> LazyHTML.attribute("class")
      assert class |> String.split(" ") |> Enum.member?("dark")
      assert html =~ "component: hello"
    end

    test "it renders a playground with a variation group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(
          conn,
          "/storybook/iframe/a_folder/component",
          %{"variation_id" => "group", "playground" => true}
        )

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end
  end

  test "it raises with an unknown story", %{conn: conn} do
    assert_raise RuntimeError, fn ->
      live_with_params(conn, "/storybook/iframe/unknown", %{"variation_id" => "default"})
    end
  end

  test "broadcasts iframe pid when topic is provided", %{conn: conn} do
    topic = "psb-component-iframe-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(PhoenixStorybook.PubSub, topic)

    {:ok, _view, _html} =
      live_with_params(conn, "/storybook/iframe/component", %{
        "variation_id" => "hello",
        "topic" => topic
      })

    assert_receive {:component_iframe_pid, pid}
    assert is_pid(pid)
  end

  test "handle_params raises StoryNotFound for not_found backend" do
    socket = base_socket(BackendNotFound)

    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      ComponentIframeLive.handle_params(%{"story" => ["missing"]}, "/", socket)
    end
  end

  test "handle_params assigns empty extra_assigns when variation is nil" do
    socket = base_socket(BackendComponentEmpty)

    {:noreply, socket} =
      ComponentIframeLive.handle_params(%{"story" => ["empty"]}, "/", socket)

    assert socket.assigns.variation == nil
    assert socket.assigns.extra_assigns == %{}
  end

  test "handle_params returns nil variation for non-component stories" do
    socket = base_socket(BackendPage)

    {:noreply, socket} =
      ComponentIframeLive.handle_params(%{"story" => ["page"]}, "/", socket)

    assert socket.assigns.variation == nil
  end

  test "variation_extra_attributes ignores theme when no strategy configured" do
    assigns =
      Map.put(
        %{
          backend_module: BackendNoTheme,
          story: DummyStory,
          variation: %Variation{id: :one},
          variation_id: nil,
          extra_assigns: %{{:single, :one} => %{foo: "bar"}},
          theme: nil,
          playground: false,
          color_mode: nil,
          topic: nil
        },
        :__changed__,
        %{}
      )

    assert %Phoenix.LiveView.Rendered{} = ComponentIframeLive.render(assigns)
  end

  test "variation_extra_attributes keeps group assigns when no theme strategy configured" do
    assigns =
      Map.put(
        %{
          backend_module: BackendNoTheme,
          story: DummyStory,
          variation: %VariationGroup{
            id: :group,
            variations: [%Variation{id: :one}]
          },
          variation_id: nil,
          extra_assigns: %{{:group, :one} => %{foo: "bar"}},
          theme: nil,
          playground: false,
          color_mode: nil,
          topic: nil
        },
        :__changed__,
        %{}
      )

    assert %Phoenix.LiveView.Rendered{} = ComponentIframeLive.render(assigns)
  end

  test "handle_info delegates to story when defined" do
    socket = %Socket{assigns: %{story: HandleInfoStory}}

    assert {:noreply, ^socket} =
             ComponentIframeLive.handle_info({:storybook_handle_info, self()}, socket)

    assert_receive :handled
  end

  test "handle_event falls through for unknown events" do
    socket = %Socket{assigns: %{}}
    assert {:noreply, ^socket} = ComponentIframeLive.handle_event("unknown", %{}, socket)
  end

  defp live_with_params(conn, path, params) do
    live(conn, "#{path}?#{URI.encode_query(params)}")
  end

  defp base_socket(backend_module) do
    %Socket{assigns: %{backend_module: backend_module, __changed__: %{}}}
  end
end
