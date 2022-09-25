defmodule PhxLiveStorybook.Stories.Slot do
  @moduledoc """
  A slot is one of your component slots. Its structure mimics the LiveView 0.18.0 declarative
  assigns.

  Slots declaration will populate the Playground tab of your storybook, for each of your
  components.

  Supported keys:
  - `id`: the slot id (required). Should match your component slot name.
    Use the id `:inner_block` for your component default slot.
  - `doc`: a text documentation for this slot.
  - `required`: `true` if the attribute is mandatory.
  """

  alias PhxLiveStorybook.Stories.Slot

  @enforce_keys [:id]
  defstruct [:id, :doc, required: false]

  @doc false
  def merge_slots(mod_or_fun, story_slots) do
    component_slots = read_slots(mod_or_fun)
    component_slots_map = mod_or_fun |> read_slots() |> slots_map(:name)
    story_slots_map = slots_map(story_slots, :id)
    slot_keys = Enum.uniq(Enum.map(component_slots, & &1.name) ++ Enum.map(story_slots, & &1.id))

    for slot_id <- slot_keys do
      component_slot = Map.get(component_slots_map, slot_id)
      story_slot = Map.get(story_slots_map, slot_id)
      build_slot(component_slot, story_slot)
    end
  end

  defp read_slots(fun_or_mod)

  defp read_slots(module) when is_atom(module) do
    slots = get_in(module.__components__(), [:render, :slots]) || []
    Enum.sort_by(slots, & &1.line)
  end

  defp read_slots(function) when is_function(function) do
    [module: module, name: name] = function |> Function.info() |> Keyword.take([:module, :name])
    slots = get_in(module.__components__(), [name, :slots]) || []
    Enum.sort_by(slots, & &1.line)
  end

  defp slots_map(slots, key) do
    for slot <- slots, into: %{}, do: {Map.get(slot, key), slot}
  end

  defp build_slot(nil, story_slot = %Slot{}), do: story_slot

  defp build_slot(slot, nil) do
    %Slot{
      id: slot.name,
      required: slot[:required],
      doc: slot.doc
    }
  end

  defp build_slot(slot, story_slot = %Slot{}) do
    %Slot{
      id: slot.name,
      required: merge_slot_key(story_slot, slot, :required, false),
      doc: merge_slot_key(story_slot, slot, :doc, nil)
    }
  end

  defp merge_slot_key(story_slot = %Slot{}, slot, key, default) do
    case Map.get(story_slot, key) do
      falsy when falsy in [nil, false] -> get_in(slot, [key]) || default
      val -> val
    end
  end
end
