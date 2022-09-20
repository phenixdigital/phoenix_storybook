defmodule PhxLiveStorybook.BackendBehaviour do
  @moduledoc """
  Behaviour implemented by your backend module.
  """

  alias PhxLiveStorybook.{ComponentStory, Folder, PageStory}

  @doc """
  Returns a configuration value from your config.exs storybook settings.

  `key` is the config key
  `default` is an optional default value if no value can be fetched.
  """
  @callback config(key :: atom(), default :: any()) :: any()

  @doc """
  Returns a precompiled tree of your storybook stories.
  """
  @callback stories() :: [%ComponentStory{} | %Folder{} | %PageStory{}]

  @doc """
  Returns all the leaves of the storybook content tree (ie. all stories that are
  not a folder)
  """
  @callback all_leaves() :: [%ComponentStory{} | %PageStory{}]

  @doc """
  Returns all the notes of the storybook content tree as a flat list.
  """
  @callback flat_list() :: [%ComponentStory{} | %PageStory{}]

  @doc """
  Returns a story from its absolute path.
  """
  @callback find_story_by_path(String.t()) :: %ComponentStory{} | %PageStory{}
end

defmodule PhxLiveStorybook do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias PhxLiveStorybook.Quotes.{ConfigQuotes, StoriesQuotes}
  alias PhxLiveStorybook.Stories

  @doc false
  defmacro __using__(opts) do
    {opts, _} = Code.eval_quoted(opts, [], __CALLER__)
    backend_module = __CALLER__.module
    otp_app = opts[:otp_app]
    stories = stories(opts)
    leave_stories = Stories.all_leaves(stories)

    [
      recompilation_quotes(backend_module, otp_app, leave_stories),
      ConfigQuotes.config_quotes(opts),
      StoriesQuotes.stories_quotes(opts, stories)
    ]
  end

  # This quote triggers recompilation for the module whenever something
  # under content path has been touched
  defp recompilation_quotes(backend_module, otp_app, leave_stories) do
    content_path = Application.get_env(otp_app, backend_module, []) |> Keyword.get(:content_path)
    components_pattern = if content_path, do: "#{content_path}/**/*"

    modules = for %{component: mod} <- leave_stories, !is_nil(mod), into: MapSet.new(), do: mod

    modules =
      for %{function: fun} <- leave_stories,
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

        # this file should be recompiled whenever any story file is touched
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

  defp stories(opts) do
    content_path = Keyword.get(opts, :content_path)
    folders_config = Keyword.get(opts, :folders, [])
    Stories.stories(content_path, folders_config)
  end
end
