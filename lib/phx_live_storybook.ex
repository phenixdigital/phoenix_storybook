defmodule PhxLiveStorybook do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias PhxLiveStorybook.Entries
  alias PhxLiveStorybook.Rendering.EntriesRenderer

  @doc false
  defmacro __using__(opts) do
    backend_module = __CALLER__.module

    [
      recompilation_quote(backend_module, opts),
      config_quote(backend_module, opts),
      Entries.entries_quote(backend_module, opts),
      EntriesRenderer.rendering_quote(backend_module, opts)
    ]
  end

  # This quote triggers recompilation for the module whenever something
  # under content path has been touched
  defp recompilation_quote(backend_module, opts) do
    otp_app = Keyword.get(opts, :otp_app)
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    components_pattern = if content_path, do: "#{content_path}/**/*"

    quote do
      @paths if unquote(content_path), do: Path.wildcard(unquote(components_pattern)), else: []
      @paths_hash :erlang.md5(@paths)

      # this file should be recompiled whenever any entry file is touched
      for path <- @paths do
        @external_resource path
      end

      def paths, do: @paths

      # this file should be recompiled whenever any file under content_path has been created or deleted
      def __mix_recompile__?() do
        if unquote(components_pattern) do
          unquote(components_pattern) |> Path.wildcard() |> :erlang.md5() !=
            @paths_hash
        else
          false
        end
      end
    end
  end

  # This quote provides config access helper
  defp config_quote(backend_module, opts) do
    quote do
      def config(key, default \\ nil) do
        otp_app = Keyword.get(unquote(opts), :otp_app)

        otp_app
        |> Application.get_env(unquote(backend_module), [])
        |> Keyword.get(key, default)
      end
    end
  end
end
