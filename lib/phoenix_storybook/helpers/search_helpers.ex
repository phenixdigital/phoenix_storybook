defmodule PhoenixStorybook.SearchHelpers do
  @moduledoc false
  # Credits to https://github.com/tajmone/fuzzy-search/tree/master/fts_fuzzy_match/0.2.0/elixir

  # Score consts
  # bonus for adjacent matches
  @sequential_bonus 15
  # bonus if match occurs after a separator
  @separator_bonus 30
  # bonus if match is uppercase and prev is lower
  @camel_bonus 30
  # bonus if the first letter is matched
  @first_letter_bonus 15

  # penalty applied for every letter in str before the first match
  @leading_letter_penalty -5
  # maximum penalty for leading letters
  @max_leading_letter_penalty -15
  # penalty for every letter that doesn't matter
  @unmatched_letter_penalty -1

  def search_by(pattern, list, keys) when is_list(list) do
    list
    |> Enum.map(fn item ->
      {match?, score} =
        for key <- keys, reduce: {false, 0} do
          {match_acc?, score_acc} ->
            {match?, score, _} = search(pattern, Map.get(item, key))
            {match_acc? or match?, max(score, score_acc)}
        end

      {item, match?, score}
    end)
    |> Enum.filter(fn {_item, match?, _score} -> match? end)
    |> Enum.sort_by(fn {_item, _match?, score} -> score end, :desc)
    |> Enum.map(fn {item, _match?, _score} -> item end)
  end

  def search(pattern, str) when is_binary(str) do
    _search(
      String.codepoints(pattern),
      String.codepoints(str),
      0,
      String.codepoints(str),
      1,
      nil
    )
  end

  defp _search(_, _, score, _, rec_count, _) when rec_count >= 10 do
    {false, score, []}
  end

  # pattern empty
  defp _search([], _, score, _, _, _) do
    {false, score, []}
  end

  # or str empty
  defp _search(_, [], score, _, _, _) do
    {false, score, []}
  end

  defp _search(pat, str, score, str_begin, rec_count, src_matches) do
    state = %{
      rec_match: false,
      best_rec_matches: [],
      best_rec_score: 0,
      first_match: true,
      matches: [],
      src_matches: src_matches
    }

    case _while(state, pat, str, str_begin, rec_count) do
      {:ok, state, pat} -> _calculate_score(state, str_begin, pat, score)
      false -> {false, score, []}
    end
  end

  defp _calculate_score(state, str_begin, pat, score) do
    if pat == [] do
      100
      |> _calculate_penalty(Enum.at(state[:matches], 0))
      |> _cal_unmatched(str_begin, state)
      |> _iter_matches(state[:matches], str_begin)
      |> _calculate_return(state, pat)
    else
      _calculate_return({:ok, score}, state, pat)
    end
  end

  defp _calculate_return({_, score}, state, pat) do
    cond do
      state[:rec_match] && (pat != [] || state[:best_rec_score] > score) ->
        {true, state[:best_rec_score], state[:best_rec_matches]}

      pat === [] ->
        {true, score, state[:matches]}

      true ->
        {false, score, state[:matches]}
    end
  end

  defp _calculate_penalty(out_score, match_score) do
    penalty =
      if match_score == nil do
        0
      else
        @leading_letter_penalty * match_score
      end

    if penalty < @max_leading_letter_penalty do
      out_score + @max_leading_letter_penalty
    else
      out_score + penalty
    end
  end

  defp _cal_unmatched(out_score, str_begin, state) do
    out_score +
      @unmatched_letter_penalty *
        (String.replace_suffix(Enum.join(str_begin, ""), "", "")
         |> String.length()
         |> Kernel.-(length(state[:matches])))
  end

  defp _iter_matches(out_score, matches, str_begin) do
    matches
    |> Enum.with_index()
    |> Enum.map_reduce(out_score, fn {item, count}, score ->
      {item,
       score
       |> _iter_sequential(matches, count, item)
       |> _iter_bonuses(str_begin, item)}
    end)
  end

  defp _iter_sequential(score, matches, count, item) do
    if count > 0 && item == Enum.at(matches, count - 1) + 1 do
      score + @sequential_bonus
    else
      score
    end
  end

  defp _iter_bonuses(score, str_begin, item) do
    if item > 0 do
      neighbor = Enum.at(str_begin, item - 1)

      score
      |> _camel_case(neighbor, Enum.at(str_begin, item))
      |> _separator(neighbor)
    else
      score + @first_letter_bonus
    end
  end

  defp _camel_case(score, neighbor, curr) do
    if neighbor != " " && neighbor == String.downcase(neighbor) &&
         curr != " " && curr === String.upcase(curr) do
      score + @camel_bonus
    else
      score
    end
  end

  defp _separator(score, neighbor) do
    if neighbor === "_" || neighbor === " " do
      score + @separator_bonus
    else
      score
    end
  end

  defp _while(state, [], _, _, _) do
    {:ok, state |> Map.put(:matches, Enum.reverse(state[:matches])), []}
  end

  defp _while(state, pat, [], _, _) do
    {:ok, state |> Map.put(:matches, Enum.reverse(state[:matches])), pat}
  end

  defp _while(state, pat, str = [_ | str_t], str_begin, rec_count) do
    # can't call String.downcase on a def when so here use cond
    case _check_while(state, pat, str, str_begin, rec_count) do
      {pat, state, rec_count} ->
        _while(state, pat, str_t, str_begin, rec_count)

      false ->
        false
    end
  end

  defp _check_while(state, pat = [pat_h | pat_t], str = [str_h | str_t], str_begin, rec_count) do
    if String.downcase(pat_h) === String.downcase(str_h) do
      if length(state[:matches]) >= 255 do
        false
      else
        rec_count = rec_count + 1

        state =
          state
          |> check_first_match
          |> check_recursive(pat, str_t, str_begin, rec_count)
          |> update_matches(str, str_begin)

        {pat_t, state, rec_count}
      end
    else
      {pat, state, rec_count}
    end
  end

  defp check_first_match(state) do
    if state[:first_match] && state[:src_matches] != nil do
      state
      |> Map.put(:matches, state[:src_matches])
      |> Map.put(:first_match, false)
    else
      state
    end
  end

  defp check_recursive(state, pat, str, str_begin, rec_count) do
    case _search(pat, str, 0, str_begin, rec_count, state[:matches]) do
      {true, score, matches} ->
        recursive_matches(state, score, matches)

      _ ->
        state
    end
  end

  defp recursive_matches(state, score, matches) do
    state =
      if state[:rec_match] === false ||
           score > state[:best_rec_score] do
        state
        |> Map.put(:best_rec_matches, matches)
        |> Map.put(:best_rec_score, score)
      else
        state
      end

    state
    |> Map.put(:rec_match, true)
  end

  defp update_matches(state, str, str_begin) do
    state
    |> Map.put(
      :matches,
      [
        String.replace_suffix(Enum.join(str_begin, ""), Enum.join(str, ""), "")
        |> String.length()
        | state[:matches]
      ]
    )
  end
end
