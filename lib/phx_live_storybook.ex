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
  Renders a specific story for a given component entry.
  Can be a single story or a story group.
  Returns rendered HEEx template.
  """
  @callback render_story(entry_module :: any(), story_id :: atom()) ::
              %Rendered{}

  @doc """
  Renders code snippet of a specific story for a given component entry.
  Returns rendered HEEx template.
  """
  @callback render_code(entry_module :: atom(), story_id :: atom()) ::
              %Rendered{}

  @doc """
  Renders source of a component entry.
  Returns rendered HEEx template.
  """
  @callback render_source(entry_module :: atom()) :: %Rendered{}

  @doc """
  Renders a tab content for a page entry.
  Returns rendered HEEx template.
  """
  @callback render_page(entry_module :: atom(), tab :: atom()) :: %Rendered{}
end

defmodule PhxLiveStorybook do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias PhxLiveStorybook.Entries

  alias PhxLiveStorybook.Quotes.{
    ComponentQuotes,
    ConfigQuotes,
    EntriesQuotes,
    PageQuotes,
    SourceQuotes
  }

  @doc false
  defmacro __using__(opts) do
    backend_module = __CALLER__.module
    otp_app = opts[:otp_app]
    entries = entries(backend_module, otp_app)
    leave_entries = Entries.all_leaves(entries)

    [
      recompilation_quotes(backend_module, otp_app, leave_entries),
      ConfigQuotes.config_quotes(backend_module, otp_app),
      EntriesQuotes.entries_quotes(entries),
      ComponentQuotes.component_quotes(leave_entries, __CALLER__.file),
      SourceQuotes.source_quotes(leave_entries),
      PageQuotes.page_quotes(leave_entries, __CALLER__.file)
    ]
  end

  # This quote triggers recompilation for the module whenever something
  # under content path has been touched
  defp recompilation_quotes(backend_module, otp_app, leave_entries) do
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    components_pattern = if content_path, do: "#{content_path}/**/*"

    live_component_quotes =
      for %{component: component} <- leave_entries, !is_nil(component) do
        quote do
          require unquote(component)
        end
      end

    component_quotes =
      for %{function: fun} <- leave_entries, !is_nil(fun) do
        quote do
          require unquote(Function.info(fun)[:module])
        end
      end

    tree_quote =
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

    [tree_quote] ++ live_component_quotes ++ component_quotes
  end

  defp entries(backend_module, otp_app) do
    content_path =
      otp_app |> Application.get_env(backend_module, []) |> Keyword.get(:content_path)

    folders_config = otp_app |> Application.get_env(backend_module, []) |> Keyword.get(:folders)
    Entries.entries(content_path, folders_config)
  end
end
