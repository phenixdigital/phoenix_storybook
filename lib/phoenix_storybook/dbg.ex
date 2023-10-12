defmodule PhoenixStorybook.Dbg do
  @moduledoc false

  def debug_fun(code, options, caller, device) do
    case Keyword.pop(options, :debug, false) do
      {true, options} -> Macro.dbg(code, options, caller)
      {_, options} -> custom_debug(code, options, caller, device)
    end
  end

  defp custom_debug(code, _options, caller, device) do
    alias PhoenixStorybook.Dbg

    quote do
      result = unquote(code)

      IO.puts(
        unquote(device),
        Dbg.light_green(
          "\n#{unquote(Path.relative_to(caller.file, File.cwd!()))}:#{unquote(caller.line)}"
        )
      )

      IO.puts(
        unquote(device),
        "#{unquote(Macro.to_string(code))} #{Dbg.light_green("=>")} #{result |> inspect() |> Dbg.bright()}"
      )

      result
    end
  end

  def bright(s), do: IO.ANSI.bright() <> s <> IO.ANSI.reset()
  def light_green(s), do: IO.ANSI.light_green() <> s <> IO.ANSI.reset()
end
