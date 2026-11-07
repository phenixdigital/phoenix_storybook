defmodule PhoenixStorybook.ComponentIframeLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.Socket
  alias PhoenixStorybook.Stories.{Variation, VariationGroup}
  alias PhoenixStorybook.Story.ComponentIframeLive

  @endpoint PhoenixStorybook.ComponentIframeLiveEndpoint
  @playground_topic_salt "phoenix_storybook:playground_topic"
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

    test "psb-assign on a whole-group iframe keeps the other variations' extra assigns",
         %{conn: conn} do
      {:ok, view, _html} =
        live_with_params(conn, "/storybook/iframe/templates/template_component", %{
          "variation_id" => "group"
        })

      view |> element("#set-foo-template-component-group-one") |> render_click()
      view |> element("#set-bar-template-component-group-two") |> render_click()
      view |> element("#toggle-status-template-component-group-two") |> render_click()

      html = render(view)
      assert html =~ "template_component: foo / status: false"
      assert html =~ "template_component: bar / status: true"
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

    test "it renders an example story", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/examples/iframe", %{"theme" => "default"})

      assert html =~ "Iframe example content"
      assert html =~ ~s|style="padding: 16px;"|
      assert html =~ ~s|data-foo="bar"|
    end
  end

  describe "single grouped variation" do
    test "group_id and variation_id render only that variation, through the group template",
         %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/templates/template_component", %{
          "group_id" => "group_template",
          "variation_id" => "one"
        })

      assert html =~ "group-template"
      assert html =~ "template_component: one"
      refute html =~ "template_component: two"
    end

    test "group_id alone renders the whole group", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/a_folder/component", %{"group_id" => "group"})

      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "psb-assign and psb-toggle update the single grouped variation", %{conn: conn} do
      {:ok, view, html} =
        live_with_params(conn, "/storybook/iframe/templates/template_component", %{
          "group_id" => "group",
          "variation_id" => "two"
        })

      assert html =~ "template_component: two / status: false"
      refute html =~ "template_component: one"

      view |> element("#set-foo-template-component-group-two") |> render_click()
      assert render(view) =~ "template_component: foo / status: false"

      view |> element("#toggle-status-template-component-group-two") |> render_click()
      assert render(view) =~ "template_component: foo / status: true"
    end

    test "handle_params raises StoryNotFound for an unknown group_id" do
      error = assert_iframe_story_not_found(%{"group_id" => "unknown", "variation_id" => "one"})
      assert error.message =~ ~s|unknown variation group "unknown"|
      assert error.message =~ "TreeStorybook.TemplateComponent"
    end

    test "handle_params raises StoryNotFound for an unknown variation in a known group" do
      error = assert_iframe_story_not_found(%{"group_id" => "group", "variation_id" => "unknown"})
      assert error.message =~ ~s|unknown variation "unknown" in group "group"|
      assert error.message =~ "TreeStorybook.TemplateComponent"
    end

    test "handle_params raises StoryNotFound when group_id points at a plain variation" do
      error = assert_iframe_story_not_found(%{"group_id" => "hello"})
      assert error.message =~ ~s|"hello" is a variation, not a variation group|
      assert error.message =~ "TreeStorybook.TemplateComponent"
    end

    test "handle_params raises StoryNotFound when group_id comes with playground" do
      error =
        assert_iframe_story_not_found(%{
          "group_id" => "group",
          "variation_id" => "one",
          "playground" => "true"
        })

      assert error.message =~ "group_id is not supported with playground"
    end
  end

  describe "all variations mode" do
    test "variations=all renders every variation of the story", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/component", %{"variations" => "all"})

      for variation_id <- ~w(hello world lengthy themed) do
        assert html =~ ~s|id="psb-screen-size-variation-#{variation_id}"|
      end

      assert html =~ "Hello variation"
      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "variation_id renders only that variation", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/component", %{
          "variations" => "all",
          "variation_id" => "world"
        })

      assert html =~ "component: world"
      refute html =~ "component: hello"
    end

    test "group_id renders the whole group in one section", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/a_folder/component", %{
          "variations" => "all",
          "group_id" => "group"
        })

      assert html =~ ~s|id="psb-screen-size-variation-group"|
      refute html =~ ~s|id="psb-screen-size-variation-no_attributes"|
      assert html =~ "component: hello"
      assert html =~ "component: world"
    end

    test "group_id and variation_id render one grouped variation, titled after its group",
         %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/a_folder/component", %{
          "variations" => "all",
          "group_id" => "group",
          "variation_id" => "world"
        })

      assert html =~ "Group › World variation"
      assert html =~ "component: world"
      refute html =~ "component: hello"
    end

    test "a story container with its own options replaces the default container", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/a_folder/component", %{"variations" => "all"})

      assert html =~ ~s|data-foo="bar"|
      assert html =~ ~r/class="block[^"]*"/
      refute html =~ "flex-direction: column"
    end

    test "a story without container options gets the default iframe container", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/component", %{"variations" => "all"})

      assert html =~ "flex-direction: column"
    end

    test "an :iframe container story renders its variations as divs", %{conn: conn} do
      {:ok, _view, html} =
        live_with_params(conn, "/storybook/iframe/containers/components/iframe", %{
          "variations" => "all"
        })

      assert html =~ ~s|<section id="psb-screen-size-variation-hello"|
      assert html =~ "component:"
      refute html =~ "<iframe"
    end

    test "an unknown variations param raises" do
      socket = base_socket(PhoenixStorybook.TestStorybook)

      assert_raise ArgumentError, ~r/unknown variations param "some"/, fn ->
        ComponentIframeLive.handle_params(
          %{"story" => ["component"], "variations" => "some"},
          "/",
          socket
        )
      end
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

    test "it renders a playground with a light color_mode", %{conn: conn} do
      {:ok, view, _html} =
        live_with_params(
          conn,
          "/storybook/iframe/component",
          %{"variation_id" => "hello", "playground" => true, "color_mode" => "light"}
        )

      html = view |> element(".psb-sandbox") |> render()
      [class] = html |> LazyHTML.from_fragment() |> LazyHTML.attribute("class")
      assert class |> String.split(" ") |> Enum.member?("light")
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

  test "does not broadcast iframe pid when raw topic is provided", %{conn: conn} do
    topic = "psb-component-iframe-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(PhoenixStorybook.PubSub, topic)

    {:ok, _view, _html} =
      live_with_params(conn, "/storybook/iframe/component", %{
        "variation_id" => "hello",
        "topic" => topic
      })

    refute_receive {:component_iframe_pid, _pid}, 50
  end

  test "broadcasts iframe pid when valid playground token is provided", %{conn: conn} do
    topic = "psb-component-iframe-#{System.unique_integer([:positive])}"
    token = Phoenix.Token.sign(@endpoint, @playground_topic_salt, %{"topic" => topic})
    Phoenix.PubSub.subscribe(PhoenixStorybook.PubSub, topic)

    {:ok, _view, _html} =
      live_with_params(conn, "/storybook/iframe/component", %{
        "variation_id" => "hello",
        "playground_token" => token
      })

    assert_receive {:component_iframe_pid, pid}
    assert is_pid(pid)
  end

  test "does not broadcast iframe pid when playground token is invalid", %{conn: conn} do
    topic = "psb-component-iframe-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(PhoenixStorybook.PubSub, topic)

    {:ok, _view, _html} =
      live_with_params(conn, "/storybook/iframe/component", %{
        "variation_id" => "hello",
        "playground_token" => "bad-token"
      })

    refute_receive {:component_iframe_pid, _pid}, 50
  end

  test "handle_params raises StoryNotFound for not_found backend" do
    socket = base_socket(BackendNotFound)

    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      ComponentIframeLive.handle_params(%{"story" => ["missing"]}, "/", socket)
    end
  end

  test "handle_params raises StoryNotFound for an unknown variation_id" do
    socket = base_socket(PhoenixStorybook.TestStorybook)

    error =
      assert_raise PhoenixStorybook.StoryNotFound, fn ->
        ComponentIframeLive.handle_params(
          %{"story" => ["component"], "variation_id" => "unknown"},
          "/",
          socket
        )
      end

    assert error.message =~ ~s|unknown variation "unknown"|
    assert error.message =~ "TreeStorybook.Component"
  end

  test "handle_params assigns empty extra_assigns when variation is nil" do
    socket = base_socket(BackendComponentEmpty)

    {:noreply, socket} =
      ComponentIframeLive.handle_params(%{"story" => ["empty"]}, "/", socket)

    assert socket.assigns.variation == nil
    assert socket.assigns.extra_assigns == %{}
  end

  test "handle_params raises StoryNotFound for page stories" do
    socket = base_socket(PhoenixStorybook.TestStorybook)

    error =
      assert_raise PhoenixStorybook.StoryNotFound, fn ->
        ComponentIframeLive.handle_params(%{"story" => ["a_page"]}, "/", socket)
      end

    assert error.message =~
             "story TreeStorybook.APage of type :page can't be rendered in an iframe"
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

  defp assert_iframe_story_not_found(params) do
    socket = base_socket(PhoenixStorybook.TestStorybook)
    params = Map.put(params, "story", ["templates", "template_component"])

    assert_raise PhoenixStorybook.StoryNotFound, fn ->
      ComponentIframeLive.handle_params(params, "/", socket)
    end
  end

  defp base_socket(backend_module) do
    %Socket{assigns: %{backend_module: backend_module, __changed__: %{}}}
  end
end
