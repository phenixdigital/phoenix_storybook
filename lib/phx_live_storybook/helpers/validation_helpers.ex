defmodule PhxLiveStorybook.ValidationHelpers do
  @moduledoc false

  def validate_type!(file, term, types, message) when is_list(types) do
    unless Enum.any?(types, &match_attr_type?(term, &1)), do: compile_error!(file, message)
  end

  def validate_type!(file, term, type, message) do
    unless match_attr_type?(term, type), do: compile_error!(file, message)
  end

  def match_attr_type?(nil, _type), do: true
  def match_attr_type?(_term, :any), do: true
  def match_attr_type?(term, {:tuple, s}) when is_tuple(term) and tuple_size(term) == s, do: true
  def match_attr_type?(term, :string) when is_binary(term), do: true
  def match_attr_type?(term, :atom) when is_atom(term), do: true
  def match_attr_type?(term, :integer) when is_integer(term), do: true
  def match_attr_type?(term, :float) when is_float(term), do: true
  def match_attr_type?(term, :boolean) when is_boolean(term), do: true
  def match_attr_type?(term, :list) when is_list(term), do: true
  def match_attr_type?(_min.._max, :range), do: true
  def match_attr_type?(term, :map) when is_map(term), do: true
  def match_attr_type?(term, :block) when is_binary(term), do: true
  def match_attr_type?(term, :slot) when is_binary(term), do: true
  def match_attr_type?(term, :function) when is_function(term), do: true
  def match_attr_type?(term, struct) when is_struct(term, struct), do: true
  def match_attr_type?(_term, _type), do: false

  def compile_error!(file_path, msg) do
    raise CompileError, file: file_path, description: msg
  end
end
