defmodule PhxLiveStorybook.Components.IconTest do
  use ExUnit.Case, async: true

  import PhxLiveStorybook.Components.Icon
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  setup(do: [assigns: []])

  describe "fa_icon/1" do
    test "a solid icon will render properly", %{assigns: assigns} do
      h = ~H(<.fa_icon name="book"/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book"></i>)
    end

    test "a free plan icon will always be solid", %{assigns: assigns} do
      h = ~H(<.fa_icon name="book" style={:duotone}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book"></i>)

      h = ~H(<.fa_icon name="book" style={:duotone} plan={:free}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book"></i>)
    end

    test "a pro plan icon will use its style", %{assigns: assigns} do
      h = ~H(<.fa_icon name="book" style={:duotone} plan={:pro}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-duotone fa-book"></i>)
    end

    test "icon CSS class can be extended", %{assigns: assigns} do
      h = ~H(<.fa_icon name="book" class="fa-spin"/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book fa-spin"></i>)
    end

    test "additional HTML attributes can be passed", %{assigns: assigns} do
      h = ~H(<.fa_icon name="book" title="A book"/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book" title="A book"></i>)
    end
  end

  describe "hero_icon/1" do
    test "a solid icon will render properly", %{assigns: assigns} do
      h = ~H(<.hero_icon name="cake"/>)
      assert rendered_to_string(h) =~ ~r{<svg.*</svg>}s
    end

    test "a solid icon with custom style will render properly", %{assigns: assigns} do
      normal = ~H(<.hero_icon name="cake"/>)
      mini = ~H(<.hero_icon name="cake" style={:mini}/>)
      assert rendered_to_string(mini) =~ ~r{<svg.*</svg>}s
      assert rendered_to_string(mini) != assert(rendered_to_string(normal))
    end

    test "icon CSS class can be extended", %{assigns: assigns} do
      h = ~H(<.hero_icon name="cake" class="w-2 h2"/>)
      assert rendered_to_string(h) =~ ~r{<svg.*class="w-2 h2".*</svg>}s
    end

    test "additional HTML attributes can be passed", %{assigns: assigns} do
      h = ~H(<.hero_icon name="cake" title="A cake"/>)
      assert rendered_to_string(h) =~ ~r{<svg.*title="A cake".*</svg>}s
    end
  end

  describe "user_icon/1" do
    test "fa tuple-2 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:fa, "book"}}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book"></i>)
    end

    test "fa tuple-3 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:fa, "book", :duotone}}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-solid fa-book"></i>)

      h = ~H(<.user_icon icon={{:fa, "book", :duotone}} fa_plan={:pro}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-duotone fa-book"></i>)
    end

    test "fa tuple-4 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:fa, "book", :duotone, "fa-fw"}} fa_plan={:pro}/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-duotone fa-book fa-fw"></i>)

      h = ~H(<.user_icon icon={{:fa, "book", :duotone, "fa-fw"}} fa_plan={:pro} title="Book"/>)
      assert rendered_to_string(h) =~ ~s(<i class="fa-duotone fa-book fa-fw" title="Book"></i>)
    end

    test "hero tuple-2 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:hero, "cake"}}/>)
      assert rendered_to_string(h) =~ ~r{<svg.*</svg>}s
    end

    test "hero tuple-3 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:hero, "cake", :mini}}/>)
      assert rendered_to_string(h) =~ ~r{<svg.*</svg>}s
    end

    test "hero tuple-4 form is working", %{assigns: assigns} do
      h = ~H(<.user_icon icon={{:hero, "cake", :mini, "w-2 h-2"}}/>)
      assert rendered_to_string(h) =~ ~r{<svg.*class="w-2 h-2".*</svg>}s

      h = ~H(<.user_icon icon={{:hero, "cake", :mini, "w-2 h-2"}} title="Cake"/>)
      assert rendered_to_string(h) =~ ~r{<svg.*class="w-2 h-2".*title="Cake".*</svg>}s
    end
  end
end
