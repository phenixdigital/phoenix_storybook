defmodule PhxLiveStorybook.Stories.IndexValidator do
  @moduledoc false

  import PhxLiveStorybook.ValidationHelpers

  def on_definition(env, :def, :folder_name, [], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    validate_type!(env.file, term, :string, "folder_name must return a binary")
  end

  def on_definition(env, :def, :folder_icon, [], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    validate_type!(env.file, term, :string, "folder_icon must return a binary")
  end

  def on_definition(env, :def, :entry, [entry_name], _guards, body) do
    {[do: term], _} = Code.eval_quoted(body, [], env)
    msg = "entry(#{inspect(entry_name)}) must a return a keyword list with keys :icon and :name"
    validate_type!(env.file, term, :list, msg)

    for item <- term do
      validate_type!(env.file, item, {:tuple, 2}, msg)
      {key, val} = item
      validate_type!(env.file, key, :atom, msg)
      validate_type!(env.file, val, :string, msg)

      unless key in [:icon, :name] do
        compile_error!(env.file, msg)
      end
    end
  end

  def on_definition(_env, _kind, _name, _args, _guards, _body), do: :ok
end
