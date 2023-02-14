defmodule PhoenixStorybook.ValidationHelpers do
  @moduledoc false

  def validate_type!(file, term, types, message) when is_list(types) do
    unless Enum.any?(types, &match_attr_type?(term, &1)), do: compile_error!(file, message)
  end

  def validate_type!(file, term, type, message) do
    unless match_attr_type?(term, type), do: compile_error!(file, message)
  end

  def validate_icon!(file, term, message \\ "")
  def validate_icon!(_file, nil, _message), do: :ok

  def validate_icon!(file, term, message_prefix) do
    cond do
      match_attr_type?(term, {:tuple, 2}) ->
        validate_icon_provider!(file, term)

        validate_type!(
          file,
          elem(term, 1),
          :string,
          message_prefix <> "icon name must be a binary"
        )

      match_attr_type?(term, {:tuple, 3}) ->
        validate_icon_provider!(file, term)

        validate_type!(
          file,
          elem(term, 1),
          :string,
          message_prefix <> "icon name must be a binary"
        )

        validate_type!(file, elem(term, 2), :atom, message_prefix <> "icon style must be an atom")

      match_attr_type?(term, {:tuple, 4}) ->
        validate_icon_provider!(file, term)

        validate_type!(
          file,
          elem(term, 1),
          :string,
          message_prefix <> "icon name must be a binary"
        )

        validate_type!(file, elem(term, 2), :atom, message_prefix <> "icon style must be an atom")

        validate_type!(
          file,
          elem(term, 3),
          :string,
          message_prefix <> "icon class must be a binary"
        )

      true ->
        compile_error!(
          file,
          message_prefix <>
            "icon must be a tuple 2, 3 or 4 items ({provider, name, style, class})"
        )
    end
  end

  defp validate_icon_provider!(file, term) do
    unless elem(term, 0) in [:fa, :hero],
      do: compile_error!(file, "icon provider must be either :fa or :hero")
  end

  def match_attr_type?(nil, _type), do: true
  def match_attr_type?({:eval, _term}, _type), do: true
  def match_attr_type?(_term, :any), do: true
  def match_attr_type?(term, {:tuple, s}) when is_tuple(term) and tuple_size(term) == s, do: true
  def match_attr_type?(term, :string) when is_binary(term), do: true
  def match_attr_type?(term, :atom) when is_atom(term), do: true
  def match_attr_type?(term, :integer) when is_integer(term), do: true
  def match_attr_type?(term, :float) when is_float(term), do: true
  def match_attr_type?(term, :boolean) when is_boolean(term), do: true
  def match_attr_type?(term, :list) when is_list(term), do: true
  def match_attr_type?(_min.._max, :range), do: true
  def match_attr_type?(term, :global) when is_map(term), do: true
  def match_attr_type?(term, :map) when is_map(term), do: true
  def match_attr_type?(term, :function) when is_function(term), do: true
  def match_attr_type?(term, struct) when is_struct(term, struct), do: true
  def match_attr_type?(_term, _type), do: false

  def compile_error!(file_path, msg) do
    raise CompileError, file: file_path, description: msg
  end
end
