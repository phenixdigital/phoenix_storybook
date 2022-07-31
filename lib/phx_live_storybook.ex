defmodule PhxLiveStorybook.BackendBehaviour do
  @moduledoc """
  Behaviour implemented by your backend module.

  Most of it is precompiled through macros.
  """

  alias Phoenix.LiveView.Rendered
  alias PhxLiveStorybook.{ComponentEntry, FolderEntry, PageEntry}

  @doc """
  Returns a configuration value from your config.exs storybook settings.

  `key` is the config key
  `default` is an optional default value if no value can be fetched.
  """
  @callback config(key :: atom(), default :: any()) :: any()

  @doc """
  Returns a precompiled tree of your storybook entries.
  """
  @callback entries() :: [%ComponentEntry{} | %FolderEntry{} | %PageEntry{}]

  @doc """
  Returns the all leaves of the storybook content tree (ie. whichever entries are is
  not a folder)
  """
  @callback all_leaves() :: [%ComponentEntry{} | %PageEntry{}]

  @doc """
  Returns an entry from its absolute path.
  """
  @callback find_entry_by_path(String.t()) :: %ComponentEntry{} | %PageEntry{}

  @doc """
  Renders a specific variation for a given component entry.
  Can be a single variation or a variation group.
  Returns rendered HEEx template.
  """
  @callback render_variation(entry_module :: atom(), variation_id :: atom()) :: %Rendered{}

  @doc """
  Renders code snippet of a specific variation for a given component entry.
  Returns rendered HEEx template.
  """
  @callback render_code(entry_module :: atom(), variation_id :: atom()) :: %Rendered{}

  @doc """
  Renders source of a component entry.
  Returns rendered HEEx template.
  """
  @callback render_source(entry_module :: atom()) :: %Rendered{}
end

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
      EntriesRenderer.rendering_quote(backend_module, opts),
      EntriesRenderer.source_quote(backend_module, opts)
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
      def __mix_recompile__? do
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
      @behaviour PhxLiveStorybook.BackendBehaviour

      @impl PhxLiveStorybook.BackendBehaviour
      def config(key, default \\ nil) do
        otp_app = Keyword.get(unquote(opts), :otp_app)

        otp_app
        |> Application.get_env(unquote(backend_module), [])
        |> Keyword.get(key, default)
      end
    end
  end
end
