defmodule PhoenixStorybook.Helpers.ExampleHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixStorybook.Helpers.ExampleHelpers

  @base_expected """
  defmodule Storybook.Examples.Example do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"Hello world!"
    end
  end\
  """

  describe "strip_example_source/1" do
    test "module without doc and extra sources" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with doc and without extra sources" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc do
          "This is some example."
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with multiline doc and without extra sources" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc do
          \"\"\"
          This is some example.

          It prints *hello world*.
          \"\"\"
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with inline doc and without extra sources" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc, do: "This is some example."

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with inline doc and extra sources" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc, do: "This is some example."

        def extra_sources do
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with extra sources and doc" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def extra_sources do
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]
        end

        def doc do
          "This is some example."
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with extra sources and inline doc" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def extra_sources do
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]
        end

        def doc, do: "This is some example."

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with extra sources and without doc" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def extra_sources do
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with inline extra sources and without doc" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def extra_sources, do:
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]

        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert @base_expected == strip_example_source(source)
    end

    test "module with extra sources and inline doc mixed with other functions" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def extra_sources do
          [
            "./template.html.heex",
            "./my_page_html.ex"
          ]
        end

        def render(assigns) do
          ~H"Hello world!"
        end

        def doc, do: "This is some example."

        def handle_info(_msg, socket) do
          {:noreply, socket}
        end
      end\
      """

      expected = """
      defmodule Storybook.Examples.Example do
        use Phoenix.LiveView

        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        def render(assigns) do
          ~H"Hello world!"
        end

        def handle_info(_msg, socket) do
          {:noreply, socket}
        end
      end\
      """

      assert expected == strip_example_source(source)
    end

    test "module with invalid syntax is left intact" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc do
          "This is some example."
        end

        # trailing )
        def render(assigns)) do
          ~H"Hello world!"
        end
      end\
      """

      assert source == strip_example_source(source)
    end

    test "source without a module is left intact" do
      source = """
      1 + 1\
      """

      assert source == strip_example_source(source)
    end

    test "source with multiple modules is left intact" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc do
          "This is some example."
        end

        def render(assigns) do
          ~H"Hello world!"
        end
      end
      defmodule Storybook.Examples.OtherModule do
        def answer, do: 42
      end\
      """

      assert source == strip_example_source(source)
    end

    test "comments are preserved" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc, do: "This is some example."

        # comment above render
        def render(assigns) do
          # comment inside render
          ~H"Hello world!"
        end
      end\
      """

      expected = """
      defmodule Storybook.Examples.Example do
        use Phoenix.LiveView

        # comment above render
        def render(assigns) do
          # comment inside render
          ~H"Hello world!"
        end
      end\
      """

      assert expected == strip_example_source(source)
    end

    test "inline functions are preserved" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc, do: "This is some example."

        def render(assigns) do
          ~H"Hello world!"
        end

        def mount(_params, _session, socket), do: {:ok, socket}
      end\
      """

      expected = """
      defmodule Storybook.Examples.Example do
        use Phoenix.LiveView

        def render(assigns) do
          ~H"Hello world!"
        end

        def mount(_params, _session, socket), do: {:ok, socket}
      end\
      """

      assert expected == strip_example_source(source)
    end

    test "annotations are preserved" do
      source = """
      defmodule Storybook.Examples.Example do
        use PhoenixStorybook.Story, :example

        def doc, do: "This is some example."

        @impl Phoenix.LiveView
        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      expected = """
      defmodule Storybook.Examples.Example do
        use Phoenix.LiveView

        @impl Phoenix.LiveView
        def render(assigns) do
          ~H"Hello world!"
        end
      end\
      """

      assert expected == strip_example_source(source)
    end
  end
end
