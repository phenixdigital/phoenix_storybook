defmodule PhoenixStorybook.ScreenSizeHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixStorybook.ScreenSizeHelpers

  defmodule DefaultViewportsBackend do
    def config(_key, default \\ nil), do: default
  end

  defmodule TailwindViewportsBackend do
    def config(:viewports, _default), do: [sm: {"sm", 640}, lg: {"lg", 1024}]
  end

  defmodule DisabledViewportsBackend do
    def config(:viewports, _default), do: false
  end

  defmodule MalformedViewportsBackend do
    def config(:viewports, _default), do: [tablet: 834]
  end

  defmodule EmptyViewportsBackend do
    def config(:viewports, _default), do: []
  end

  @default_screen_sizes [
    small_mobile: {"Small mobile", 320},
    large_mobile: {"Large mobile", 414},
    tablet: {"Tablet", 834},
    desktop: {"Desktop", 1280}
  ]

  describe "screen_sizes/1" do
    test "returns Storybook JS's presets by default" do
      assert screen_sizes(DefaultViewportsBackend) == @default_screen_sizes
    end

    test "returns the backend's viewports option" do
      assert screen_sizes(TailwindViewportsBackend) == [sm: {"sm", 640}, lg: {"lg", 1024}]
    end

    test "returns nil when viewports is false" do
      assert screen_sizes(DisabledViewportsBackend) == nil
    end

    test "raises on a malformed entry" do
      assert_raise ArgumentError, ~r/invalid :viewports entry/, fn ->
        screen_sizes(MalformedViewportsBackend)
      end
    end

    test "raises on an empty list" do
      assert_raise ArgumentError, ~r/invalid :viewports option/, fn ->
        screen_sizes(EmptyViewportsBackend)
      end
    end
  end

  describe "selected_screen_size/2" do
    test "returns nil without a viewport param" do
      assert selected_screen_size(@default_screen_sizes, nil) == nil
    end

    test "parses a preset key" do
      assert selected_screen_size(@default_screen_sizes, "tablet") ==
               {:preset, :tablet, "Tablet", 834}
    end

    test "parses a positive width in px" do
      assert selected_screen_size(@default_screen_sizes, "419") == {:custom, 419}
    end

    test "raises on an unknown preset key" do
      assert_raise ArgumentError, ~r/unknown viewport param "watch"/, fn ->
        selected_screen_size(@default_screen_sizes, "watch")
      end
    end

    test "raises on a zero width" do
      assert_raise ArgumentError, ~r/unknown viewport param "0"/, fn ->
        selected_screen_size(@default_screen_sizes, "0")
      end
    end

    test "raises when screen sizes are disabled" do
      assert_raise ArgumentError, ~r/screen sizes are disabled/, fn ->
        selected_screen_size(nil, "tablet")
      end
    end
  end

  describe "screen_size_width/1" do
    test "returns the width of a preset or a custom size" do
      assert screen_size_width({:preset, :tablet, "Tablet", 834}) == 834
      assert screen_size_width({:custom, 419}) == 419
    end
  end

  describe "variation_selection/3" do
    setup do
      {:ok, story} = PhoenixStorybook.TestStorybook.load_story("/a_folder/component")
      %{story: story}
    end

    test "returns :all without params", %{story: story} do
      assert variation_selection(story, nil, nil) == :all
    end

    test "selects a plain variation", %{story: story} do
      assert {:variation, %{id: :no_attributes}} =
               variation_selection(story, nil, "no_attributes")
    end

    test "selects a whole group", %{story: story} do
      assert {:group, %{id: :group}} = variation_selection(story, "group", nil)
    end

    test "selects one variation of a group", %{story: story} do
      assert {:grouped_variation, %{id: :group}, %{id: :world}} =
               variation_selection(story, "group", "world")
    end

    test "raises when variation_id names a group", %{story: story} do
      assert_raise ArgumentError, ~r/is a variation group, use group_id=group/, fn ->
        variation_selection(story, nil, "group")
      end
    end

    test "raises on an unknown variation_id", %{story: story} do
      assert_raise ArgumentError, ~r/unknown variation_id "unknown"/, fn ->
        variation_selection(story, nil, "unknown")
      end
    end

    test "raises on an unknown group", %{story: story} do
      assert_raise ArgumentError, ~r/unknown group_id "unknown"/, fn ->
        variation_selection(story, "unknown", nil)
      end
    end

    test "raises on an unknown variation of a group", %{story: story} do
      assert_raise ArgumentError, ~r/unknown variation_id "unknown" in group "group"/, fn ->
        variation_selection(story, "group", "unknown")
      end
    end
  end

  describe "variation_selection_params/1 and variation_selection_query/1" do
    setup do
      {:ok, story} = PhoenixStorybook.TestStorybook.load_story("/a_folder/component")
      %{story: story}
    end

    test "round-trip every kind of selection", %{story: story} do
      for {group_id, variation_id, expected_query} <- [
            {nil, nil, ""},
            {nil, "no_attributes", "variation_id=no_attributes"},
            {"group", nil, "group_id=group"},
            {"group", "world", "group_id=group&variation_id=world"}
          ] do
        selection = variation_selection(story, group_id, variation_id)
        params = variation_selection_params(selection)

        assert (params.group_id && to_string(params.group_id)) == group_id
        assert (params.variation_id && to_string(params.variation_id)) == variation_id
        assert variation_selection_query(selection) == expected_query
      end
    end
  end
end
