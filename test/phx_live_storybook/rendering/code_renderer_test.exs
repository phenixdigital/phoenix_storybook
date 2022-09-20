defmodule PhxLiveStorybook.Rendering.CodeRendererTest do
  use ExUnit.Case, async: true

  describe "render_variation_code/2" do
    test "it should return HEEX for each component/variation couple" do
      code = render_variation_code(Elixir.TreeStorybook.Component, :hello)
      assert code =~ ~r|<pre.*</pre>|s

      code = render_variation_code(Elixir.TreeStorybook.Component, :world)
      assert code =~ ~r|<pre.*</pre>|s

      code = render_variation_code(Elixir.TreeStorybook.LiveComponent, :hello)
      assert code =~ ~r|<pre.*</pre>|s

      code = render_variation_code(Elixir.TreeStorybook.LiveComponent, :world)
      assert code =~ ~r|<pre.*</pre>|s
    end

    test "it also works for a variation group" do
      code = render_variation_code(Elixir.TreeStorybook.AFolder.Component, :group)
      assert code =~ ~r|<pre.*</pre>|s

      code = render_variation_code(Elixir.TreeStorybook.AFolder.LiveComponent, :group)
      assert code =~ ~r|<pre.*</pre>|s
    end

    test "it is working with a variation without any attributes" do
      code = render_variation_code(Elixir.TreeStorybook.AFolder.Component, :no_attributes)
      assert code =~ ~r|<pre.*</pre>|s
    end

    test "it is working with an inner_block requiring a let attribute" do
      code = render_variation_code(Elixir.TreeStorybook.Let.LetComponent, :default)
      assert code =~ ~r|<pre.*</pre>|s
    end

    test "it is working with an inner_block requiring a let attribute, in a live component" do
      code = render_variation_code(Elixir.TreeStorybook.Let.LetLiveComponent, :default)
      assert code =~ ~r|<pre.*</pre>|s
    end

    test "it is working with a template component" do
      code = render_variation_code(Elixir.TreeStorybook.TemplateComponent, :hello)
      assert Regex.match?(~r/<pre.*template-div.*\/pre>/s, code)
    end

    test "it prints aliases struct names" do
      code = render_variation_code(Elixir.TreeStorybook.BFolder.AllTypesComponent, :with_struct)
      assert Regex.match?(~r/<pre.*Struct.*\/pre>/s, code)
      refute Regex.match?(~r/<pre.*AllTypesComponent.*\/pre>/s, code)
    end
  end

  defp render_variation_code(story, variation_id) do
    PhxLiveStorybook.Rendering.CodeRenderer.render_variation_code(story, variation_id)
    |> Phoenix.LiveViewTest.rendered_to_string()
  end
end
