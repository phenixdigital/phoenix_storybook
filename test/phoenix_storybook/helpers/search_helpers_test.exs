defmodule PhoenixStorybook.SearchHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixStorybook.SearchHelpers

  describe "search/2" do
    test "simple search" do
      assert {true, _, _} = search("a", "abc")
      assert {true, _, _} = search("b", "abc")
      assert {true, _, _} = search("ab", "abc")
      assert {false, _, _} = search("d", "abc")
      assert {false, _, _} = search("ba", "abc")
      assert {false, _, _} = search("", "abc")
    end

    test "fuzzy search" do
      assert {true, _, _} = search("LCnt", "LiveComponent")
      assert {true, _, _} = search("lcnt", "LiveComponent")
      assert {true, _, _} = search("lcnt", "LiveComponent")
      assert {false, _, _} = search("lcZnt", "LiveComponent")
    end
  end

  describe "search_by/3" do
    test "simple search" do
      assert [%{t: "abc"}, %{t: "addbc"}] =
               search_by("ab", [%{t: "addbc"}, %{t: "abc"}, %{t: "xy"}], [:t])
    end

    test "multi-key search" do
      assert [%{t: "abc", n: "Wahou"}, %{t: "awaha", n: "bar"}] =
               search_by(
                 "wah",
                 [%{t: "abc", n: "Wahou"}, %{t: "addbc", n: "foo"}, %{t: "awaha", n: "bar"}],
                 [:t, :n]
               )
    end
  end
end
