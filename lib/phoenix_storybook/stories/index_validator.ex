defmodule PhoenixStorybook.Stories.IndexValidator do
  @moduledoc false

  import PhoenixStorybook.ValidationHelpers

  def on_definition(env, :def, :folder_name, [], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    validate_type!(env.file, term, :string, "folder_name must return a binary")
  end

  def on_definition(env, :def, :folder_icon, [], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    validate_icon!(env.file, term, "folder_icon is invalid: ")
  end

  def on_definition(env, :def, :entry, [entry_name], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    msg = "entry(#{inspect(entry_name)}) must return a keyword list with keys :icon and :name"
    validate_type!(env.file, term, :list, msg)

    Enum.each(term, fn
      {:name, name} ->
        validate_type!(env.file, name, :string, "entry(#{inspect(entry_name)}) must be a string")

      {:icon, icon} ->
        validate_icon!(env.file, icon, "entry(#{inspect(entry_name)}) icon is invalid: ")

      _ ->
        compile_error!(env.file, msg)
    end)
  end

  def on_definition(_env, _kind, _name, _args, _guards, _body), do: :ok
end
