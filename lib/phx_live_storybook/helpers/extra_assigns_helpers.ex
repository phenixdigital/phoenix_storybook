defmodule PhxLiveStorybook.ExtraAssignsHelpers do
  @moduledoc false

  alias PhxLiveStorybook.Stories.Attr

  def handle_set_variation_assign(params, extra_assigns, story) do
    context = "assign"
    variation_id = to_variation_id(params, context)
    params = Map.delete(params, "variation_id")

    variation_extra_assigns = to_variation_extra_assigns(extra_assigns, variation_id)

    variation_extra_assigns =
      for {attr, value} <- params, reduce: variation_extra_assigns do
        acc ->
          attr = String.to_atom(attr)
          value = to_value(value, attr, story.attributes(), context)
          Map.put(acc, attr, value)
      end

    {variation_id, variation_extra_assigns}
  end

  def handle_toggle_variation_assign(params, extra_assigns, story) do
    context = "toggle"

    attr =
      params
      |> Map.get_lazy("attr", fn -> raise "missing attr in #{context}" end)
      |> String.to_atom()

    variation_id = to_variation_id(params, context)
    variation_extra_assigns = to_variation_extra_assigns(extra_assigns, variation_id)
    current_value = Map.get(variation_extra_assigns, attr)
    check_type!(current_value, :boolean, context)

    case declared_attr_type(attr, story.attributes()) do
      nil ->
        :ok

      :boolean ->
        :ok

      type ->
        raise(
          RuntimeError,
          "type mismatch in #{context}: attribute #{attr} is a #{type}, should be a boolean"
        )
    end

    variation_extra_assigns = Map.put(variation_extra_assigns, attr, !current_value)
    {variation_id, variation_extra_assigns}
  end

  defp to_variation_id(%{"variation_id" => [group_id, variation_id]}, _ctx),
    do: {String.to_atom(group_id), String.to_atom(variation_id)}

  defp to_variation_id(%{"variation_id" => variation_id}, _ctx),
    do: {:single, String.to_atom(variation_id)}

  defp to_variation_id(_, context), do: raise("missing variation_id in #{context}")

  defp to_variation_extra_assigns(extra_assigns, id = {_group_id, _variation_id}) do
    Map.get(extra_assigns, id)
  end

  defp to_value("nil", _attr_id, _attributes, _context), do: nil

  defp to_value(val, attr_id, attributes, context) when is_binary(val) do
    case declared_attr_type(attr_id, attributes) do
      :atom -> val |> String.to_atom() |> check_type!(:atom, context)
      :boolean -> val |> String.to_atom() |> check_type!(:boolean, context)
      :integer -> val |> Integer.parse() |> check_type!(:integer, context)
      :float -> val |> Float.parse() |> check_type!(:float, context)
      _ -> val
    end
  end

  defp to_value(val, attr_id, attributes, context) do
    case declared_attr_type(attr_id, attributes) do
      type when type in ~w(atom boolean integer float)a -> check_type!(val, type, context)
      _ -> val
    end
  end

  defp declared_attr_type(attr_id, attributes) do
    case Enum.find(attributes, fn %Attr{id: id} -> id == attr_id end) do
      %Attr{type: type} -> type
      _ -> nil
    end
  end

  defp check_type!(nil, _type, _context), do: nil
  defp check_type!(atom, :atom, _context) when is_atom(atom), do: atom
  defp check_type!(boolean, :boolean, _context) when is_boolean(boolean), do: boolean
  defp check_type!({integer, _}, :integer, _context) when is_integer(integer), do: integer
  defp check_type!(integer, :integer, _context) when is_integer(integer), do: integer
  defp check_type!({float, _}, :float, _context) when is_float(float), do: float
  defp check_type!(float, :float, _context) when is_float(float), do: float

  defp check_type!(value, type, context) do
    raise(RuntimeError, "type mismatch in #{context}: #{value} is not a #{type}")
  end
end
