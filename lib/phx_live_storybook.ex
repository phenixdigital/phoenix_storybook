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
  Returns all the leaves of the storybook content tree (ie. all entries that are
  not a folder)
  """
  @callback all_leaves() :: [%ComponentEntry{} | %PageEntry{}]

  @doc """
  Returns all the notes of the storybook content tree as a flat list.
  """
  @callback flat_list() :: [%ComponentEntry{} | %PageEntry{}]

  @doc """
  Returns an entry from its absolute path.
  """
  @callback find_entry_by_path(String.t()) :: %ComponentEntry{} | %PageEntry{}

  @doc """
  Renders a specific variation for a given component entry.
  Can be a single variation or a variation group.
  Returns a rendered HEEx template.
  """
  @callback render_variation(
              entry_module :: any(),
              variation_id :: atom(),
              theme :: atom()
            ) ::
              %Rendered{}

  @doc """
  Renders code snippet of a specific variation for a given component entry.
  Returns a rendered HEEx template.
  """
  @callback render_code(entry_module :: atom(), variation_id :: atom()) ::
              %Rendered{}

  @doc """
  Renders source of a component entry.
  Returns a rendered HEEx template.
  """
  @callback render_source(entry_module :: atom()) :: %Rendered{}

  @doc """
  Renders a tab content for a page entry.
  Returns a rendered HEEx template.
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
    {opts, _} = Code.eval_quoted(opts, [], __CALLER__)
    backend_module = __CALLER__.module
    otp_app = opts[:otp_app]
    entries = entries(opts)
    themes = Keyword.get(opts, :themes, [{nil, nil}])
    leave_entries = Entries.all_leaves(entries)

    [
      recompilation_quotes(backend_module, otp_app, leave_entries),
      ConfigQuotes.config_quotes(opts),
      EntriesQuotes.entries_quotes(entries),
      ComponentQuotes.render_component_quotes(leave_entries, themes),
      ComponentQuotes.render_code_quotes(leave_entries),
      SourceQuotes.source_quotes(leave_entries),
      PageQuotes.page_quotes(leave_entries, themes, __CALLER__.file)
    ]
  end

  # This quote triggers recompilation for the module whenever something
  # under content path has been touched
  defp recompilation_quotes(backend_module, otp_app, leave_entries) do
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    components_pattern = if content_path, do: "#{content_path}/**/*"

    modules = for %{component: mod} <- leave_entries, !is_nil(mod), into: MapSet.new(), do: mod

    modules =
      for %{function: fun} <- leave_entries,
          !is_nil(fun),
          into: modules,
          do: Function.info(fun)[:module]

    modules_with_paths = for mod <- modules, do: {mod, to_string(mod.__info__(:compile)[:source])}

    component_quotes =
      for {module, path} <- modules_with_paths do
        quote do
          @external_resource unquote(path)
          require unquote(module)
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

        # this file should be recompiled whenever any file under content_path has been created or
        # deleted
        def __mix_recompile__? do
          if unquote(components_pattern) do
            unquote(components_pattern) |> Path.wildcard() |> :erlang.md5() !=
              @paths_hash
          else
            false
          end
        end
      end

    [tree_quote | component_quotes]
  end

  defp entries(opts) do
    content_path = Keyword.get(opts, :content_path)
    folders_config = Keyword.get(opts, :folders, [])
    Entries.entries(content_path, folders_config)
  end
end
