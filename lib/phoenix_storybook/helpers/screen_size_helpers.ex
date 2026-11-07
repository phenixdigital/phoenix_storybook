defmodule PhoenixStorybook.ScreenSizeHelpers do
  @moduledoc false

  alias PhoenixStorybook.Stories.{Variation, VariationGroup}

  # Storybook JS MINIMAL_VIEWPORTS widths.
  @default_screen_sizes [
    small_mobile: {"Small mobile", 320},
    large_mobile: {"Large mobile", 414},
    tablet: {"Tablet", 834},
    desktop: {"Desktop", 1280}
  ]

  @doc """
  Returns the configured screen sizes as `[{preset_key, {label, width_px}}]`, or `nil` when the
  backend sets `viewports: false`. Raises on a malformed `viewports:` option.
  """
  def screen_sizes(backend_module) do
    case backend_module.config(:viewports, @default_screen_sizes) do
      false ->
        nil

      screen_sizes when is_list(screen_sizes) and screen_sizes != [] ->
        Enum.each(screen_sizes, &validate_screen_size!/1)
        screen_sizes

      other ->
        raise ArgumentError,
              "invalid :viewports option #{inspect(other)}, expected false or a non-empty keyword " <>
                ~s(list like [small_mobile: {"Small mobile", 320}])
    end
  end

  defp validate_screen_size!({preset_key, {label, width_px}})
       when is_atom(preset_key) and is_binary(label) and is_integer(width_px) and width_px > 0,
       do: :ok

  defp validate_screen_size!(other) do
    raise ArgumentError,
          "invalid :viewports entry #{inspect(other)}, expected {preset_key, {label, width_px}} " <>
            ~s(like {:tablet, {"Tablet", 834}})
  end

  @doc """
  Parses the `viewport` story page param (a preset key or a width in px).
  Returns `nil`, `{:preset, preset_key, label, width_px}` or `{:custom, width_px}`.
  """
  def selected_screen_size(_screen_sizes, nil), do: nil

  def selected_screen_size(nil, viewport_param) do
    raise ArgumentError,
          "viewport param #{inspect(viewport_param)} given but screen sizes are disabled (viewports: false)"
  end

  def selected_screen_size(screen_sizes, viewport_param) do
    preset =
      Enum.find(screen_sizes, fn {preset_key, _} -> to_string(preset_key) == viewport_param end)

    case {preset, Integer.parse(viewport_param)} do
      {{preset_key, {label, width_px}}, _} ->
        {:preset, preset_key, label, width_px}

      {nil, {width_px, ""}} when width_px > 0 ->
        {:custom, width_px}

      _ ->
        preset_keys = Enum.map_join(screen_sizes, ", ", fn {preset_key, _} -> preset_key end)

        raise ArgumentError,
              "unknown viewport param #{inspect(viewport_param)}, expected one of #{preset_keys} " <>
                "or a positive width in px"
    end
  end

  def screen_size_width({:preset, _preset_key, _label, width_px}), do: width_px
  def screen_size_width({:custom, width_px}), do: width_px

  @doc """
  Parses the `group_id` / `variation_id` story page params of the screen-size preview, with the
  same contract as the iframe route. Returns `:all`, `{:variation, variation}`, `{:group, group}`
  or `{:grouped_variation, group, variation}`. Raises on anything that doesn't exist.
  """
  def variation_selection(_story, nil, nil), do: :all

  def variation_selection(story, nil, variation_id) do
    case find_by_id(story.variations(), variation_id) do
      variation = %Variation{} ->
        {:variation, variation}

      %VariationGroup{} ->
        raise ArgumentError,
              "#{inspect(variation_id)} is a variation group, use group_id=#{variation_id}"

      nil ->
        raise ArgumentError, "unknown variation_id #{inspect(variation_id)}"
    end
  end

  def variation_selection(story, group_id, variation_id) do
    group =
      case find_by_id(story.variations(), group_id) do
        group = %VariationGroup{} -> group
        _ -> raise ArgumentError, "unknown group_id #{inspect(group_id)}"
      end

    case variation_id do
      nil ->
        {:group, group}

      variation_id ->
        {:grouped_variation, group,
         find_by_id(group.variations, variation_id) ||
           raise(
             ArgumentError,
             "unknown variation_id #{inspect(variation_id)} in group #{inspect(group_id)}"
           )}
    end
  end

  defp find_by_id(variations, wanted_id),
    do: Enum.find(variations, &(to_string(&1.id) == wanted_id))

  @doc "The `group_id` / `variation_id` params for a selection (inverse of `variation_selection/3`)."
  def variation_selection_params(:all), do: %{group_id: nil, variation_id: nil}

  def variation_selection_params({:variation, variation}),
    do: %{group_id: nil, variation_id: variation.id}

  def variation_selection_params({:group, group}), do: %{group_id: group.id, variation_id: nil}

  def variation_selection_params({:grouped_variation, group, grouped_variation}),
    do: %{group_id: group.id, variation_id: grouped_variation.id}

  @doc "The query string of a selection's params, used as its option value in the Variation select."
  def variation_selection_query(selection) do
    selection
    |> variation_selection_params()
    |> Enum.reject(fn {_param, param_value} -> is_nil(param_value) end)
    |> Enum.sort()
    |> URI.encode_query()
  end
end
