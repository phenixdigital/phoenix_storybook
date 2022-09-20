defmodule PhxLiveStorybook.Rendering.ComponentRendererTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  describe "render_variation/2" do
    alias Elixir.TreeStorybook.{
      Component,
      LiveComponent,
      InvalidTemplateComponent,
      TemplateComponent
    }

    test "it should return HEEX for each component/variation couple" do
      assert render_variation(Component, :hello) |> rendered_to_string() ==
               "<span data-index=\"42\">component: hello</span>"

      assert render_variation(Component, :world) |> rendered_to_string() ==
               "<span data-index=\"37\">component: world</span>"

      # I did not manage to assert against the HTML
      assert [%Phoenix.LiveView.Component{id: "live_component-hello"}] =
               render_variation(LiveComponent, :hello).dynamic.([])

      assert [%Phoenix.LiveView.Component{id: "live_component-world"}] =
               render_variation(LiveComponent, :world).dynamic.([])
    end

    test "it also works for a variation group" do
      assert render_variation(Elixir.TreeStorybook.AFolder.Component, :group)
             |> rendered_to_string() ==
               String.trim("""
               <span data-index=\"42\">component: hello</span>
               <span data-index=\"37\">component: world</span>
               """)

      # I did not manage to assert against the HTML
      assert [
               %Phoenix.LiveView.Component{id: "live_component-group-hello"},
               %Phoenix.LiveView.Component{id: "live_component-group-world"}
             ] =
               render_variation(
                 Elixir.TreeStorybook.AFolder.LiveComponent,
                 :group
               ).dynamic.([])
    end

    test "it is working with a variation without any attributes" do
      assert render_variation(
               Elixir.TreeStorybook.AFolder.Component,
               :no_attributes
             )
             |> rendered_to_string() ==
               "<span data-index=\"42\">component: </span>"
    end

    test "it is working with an inner_block requiring a let attribute" do
      html =
        render_variation(Elixir.TreeStorybook.Let.LetComponent, :default)
        |> rendered_to_string()

      assert html =~ "**foo**"
      assert html =~ "**bar**"
      assert html =~ "**qix**"
    end

    test "it is working with an inner_block requiring a let attribute, in a live component" do
      assert [%Phoenix.LiveView.Component{id: "let_live_component-default"}] =
               render_variation(
                 Elixir.TreeStorybook.Let.LetLiveComponent,
                 :default
               ).dynamic.([])
    end

    test "renders a variation with story template" do
      html =
        render_variation(TemplateComponent, :hello)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") |> hd() == "hello"
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation with its own template" do
      html =
        render_variation(TemplateComponent, :variation_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> hd() == "variation-template"
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation with which disables story's template" do
      html =
        render_variation(TemplateComponent, :no_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") == []
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation group with story template" do
      html =
        render_variation(TemplateComponent, :group)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") |> length() == 2
      assert html |> Floki.attribute("id") |> Enum.at(0) == "group:one"
      assert html |> Floki.attribute("id") |> Enum.at(1) == "group:two"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation group with its own template" do
      html =
        render_variation(TemplateComponent, :group_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> length() == 2
      assert html |> Floki.attribute("class") |> Enum.at(0) == "group-template"
      assert html |> Floki.attribute("class") |> Enum.at(1) == "group-template"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation group with a <.lsb-variation-group/> placeholder template" do
      html =
        render_variation(TemplateComponent, :group_template_single)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> length() == 1
      assert html |> Floki.attribute("class") |> Enum.at(0) == "group-template"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation with a template, but no placeholder" do
      assert render_variation(TemplateComponent, :no_placeholder)
             |> rendered_to_string() == "<div></div>"
    end

    test "renders a variation group with a template, but no placeholder" do
      assert render_variation(TemplateComponent, :no_placeholder_group)
             |> rendered_to_string() == "<div></div>"
    end

    test "renders a variation with an invalid template placeholder will raise" do
      msg = "Cannot use <.lsb-variation-group/> placeholder in a variation template."

      assert_raise RuntimeError, msg, fn ->
        render_variation(InvalidTemplateComponent, :invalid_template_placeholder)
      end
    end

    test "renders a variation with a template passing extra attributes" do
      assert render_variation(TemplateComponent, :template_attributes)
             |> rendered_to_string() ==
               "<span>template_component: from_template / status: true</span>"
    end
  end

  defp render_variation(story, variation_id) do
    PhxLiveStorybook.Rendering.ComponentRenderer.render_variation(story, variation_id, %{})
  end
end
