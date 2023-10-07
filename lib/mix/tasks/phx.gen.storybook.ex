defmodule Mix.Tasks.Phx.Gen.Storybook do
  @shortdoc "Generates a Storybook to showcase your LiveComponents"
  @moduledoc """
  Generates a Storybook and provides setup instructions.

  ```bash
  $> mix phx.gen.storybook
  ```

  The generated files will contain:

    * a storybook backend in `lib/my_app_web/storybook.ex`
    * a custom js file in `assets/js/storybook.js`
    * a custom css file in `assets/css/storybook.css`
    * scaffolding including example stories for your own storybook in `storybook/`

  The generator supports the `--no-tailwind` flag if you want to skip the TailwindCSS specific bit.
  """

  use Mix.Task

  @requirements ["app.config"]
  @templates_folder "priv/templates/phx.gen.storybook"
  @switches [tailwind: :boolean]

  @doc false
  def run(argv) do
    opts = parse_opts(argv)

    if Mix.Project.umbrella?() do
      Mix.raise("""
      umbrella projects are not supported.
      mix phx.gen.storybook must be invoked from within your *_web application root directory")
      """)
    end

    Mix.shell().info("Starting storybook generation")

    web_module = web_module()
    web_module_name = Module.split(web_module) |> List.last()
    core_components_module = Module.concat([web_module, :CoreComponents])
    core_components_module_name = Macro.to_string(core_components_module)
    app_name = String.to_atom(Macro.underscore(web_module))
    app_folder = Path.join("lib", to_string(app_name))
    core_components_folder = "storybook/core_components"
    page_folder = "storybook"
    js_folder = "assets/js"
    css_folder = "assets/css"

    schema = %{
      app: app_name,
      sandbox_class: String.replace(to_string(app_name), "_", "-"),
      module: web_module,
      core_components_module: core_components_module,
      core_components_module_name: core_components_module_name
    }

    mapping =
      [
        {"storybook.ex.eex", Path.join(app_folder, "storybook.ex")},
        {"_root.index.exs", Path.join(page_folder, "_root.index.exs")},
        {"welcome.story.exs", Path.join(page_folder, "welcome.story.exs")}
      ] ++
        maybe_core_components(core_components_module, core_components_folder) ++
        maybe_core_components_example(core_components_module) ++
        stylesheet(css_folder, opts[:tailwind]) ++
        [{"storybook.js", Path.join(js_folder, "storybook.js")}]

    for {source_file_path, target} <- mapping do
      templates_folder = Application.app_dir(:phoenix_storybook, @templates_folder)
      source = Path.join(templates_folder, source_file_path)

      source_content =
        case Path.extname(source) do
          ".eex" -> EEx.eval_file(source, schema: schema)
          _ -> File.read!(source)
        end

      Mix.Generator.create_file(target, source_content)
    end

    with true <- print_router_instructions(web_module_name, app_name, opts),
         true <- print_esbuild_instructions(web_module_name, app_name, opts),
         true <- print_tailwind_instructions(web_module_name, app_name, opts),
         true <- print_watchers_instructions(web_module_name, app_name, opts),
         true <- print_live_reload_instructions(web_module_name, app_name, opts),
         true <- print_formatter_instructions(web_module_name, app_name, opts),
         true <- print_mixexs_instructions(web_module_name, app_name, opts),
         true <- print_docker_instructions(web_module_name, app_name, opts) do
      Mix.shell().info("You are all set! 🚀")
      Mix.shell().info("You can run mix phx.server and visit http://localhost:4000/storybook")
    else
      _ -> Mix.shell().info("storybook setup aborted 🙁")
    end
  end

  defp maybe_core_components(core_components_module, folder) do
    dir = Application.app_dir(:phoenix_storybook, @templates_folder)
    stories = dir |> Path.join("/core_components/*.story.*") |> Path.wildcard()

    for story_path <- stories,
        component_defined?(story_path, core_components_module),
        basename = Path.basename(story_path),
        story_name = String.trim_trailing(basename, ".eex") do
      {Path.join("core_components", basename), Path.join(folder, story_name)}
    end
  end

  defp component_defined?(story_path, module) do
    function =
      story_path
      |> Path.basename()
      |> String.split(".")
      |> hd()
      |> String.to_atom()

    Code.ensure_loaded?(module) && function_exported?(module, function, 1)
  end

  defp maybe_core_components_example(core_components_module) do
    if Code.ensure_loaded?(core_components_module) &&
         Enum.all?(~w(button header table modal input simple_form)a, fn function ->
           function_exported?(core_components_module, function, 1)
         end) do
      [
        {"examples/core_components.story.exs.eex", "storybook/examples/core_components.story.exs"}
      ]
    else
      []
    end
  end

  defp stylesheet(css_folder, _tailwind = false),
    do: [{"storybook.css.eex", Path.join(css_folder, "storybook.css")}]

  defp stylesheet(css_folder, _tailwind),
    do: [{"storybook.tailwind.css", Path.join(css_folder, "storybook.css")}]

  defp web_module do
    base = Mix.Phoenix.base()

    cond do
      Mix.Phoenix.context_app() != Mix.Phoenix.otp_app() -> Module.concat([base])
      String.ends_with?(base, "Web") -> Module.concat([base])
      true -> Module.concat(["#{base}Web"])
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches) do
      {opts, [], []} ->
        opts

      {_opts, [argv | _], _} ->
        Mix.raise("Invalid option: #{argv}")

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp print_router_instructions(web_module, _app_name, _opts) do
    print_instructions("""
      Add the following to your #{IO.ANSI.bright()}router.ex#{IO.ANSI.reset()}:

        use #{web_module}, :router
        import PhoenixStorybook.Router

        scope "/" do
          storybook_assets()
        end

        scope "/", #{web_module} do
          pipe_through(:browser)
          live_storybook "/storybook", backend_module: #{web_module}.Storybook
        end
    """)
  end

  defp print_esbuild_instructions(_web_module, _app_name, _opts) do
    print_instructions("""
      Add #{IO.ANSI.bright()}js/storybook.js#{IO.ANSI.reset()} as a new entry point to your esbuild args in #{IO.ANSI.bright()}config/config.exs#{IO.ANSI.reset()}:

        config :esbuild,
        default: [
          args:
            ~w(js/app.js #{IO.ANSI.bright()}js/storybook.js#{IO.ANSI.reset()} --bundle --target=es2017 --outdir=../priv/static/assets ...),
          ...
        ]
    """)
  end

  defp print_tailwind_instructions(_web_module, _app_name, _opts = [tailwind: false]), do: true

  defp print_tailwind_instructions(_web_module, _app_name, _opts) do
    print_instructions("""
      Add a new Tailwind build profile for #{IO.ANSI.bright()}css/storybook.css#{IO.ANSI.reset()} in #{IO.ANSI.bright()}config/config.exs#{IO.ANSI.reset()}:

        config :tailwind,
          ...
          default: [
            ...
          ],
          #{IO.ANSI.bright()}storybook: [
            args: ~w(
              --config=tailwind.config.js
              --input=css/storybook.css
              --output=../priv/static/assets/storybook.css
            ),
            cd: Path.expand("../assets", __DIR__)
          ]#{IO.ANSI.reset()}
    """)
  end

  defp print_watchers_instructions(_web_module, _app_name, _opts = [tailwind: false]), do: true

  defp print_watchers_instructions(web_module, app_name, _opts) do
    print_instructions("""
      Add a new #{IO.ANSI.bright()}endpoint watcher#{IO.ANSI.reset()} for your new Tailwind build profile in #{IO.ANSI.bright()}config/dev.exs#{IO.ANSI.reset()}:

        config #{inspect(app_name)}, #{web_module}.Endpoint,
          ...
          watchers: [
            ...
            #{IO.ANSI.bright()}storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]}#{IO.ANSI.reset()}
          ]
    """)
  end

  defp print_live_reload_instructions(web_module, app_name, _opts) do
    print_instructions("""
      Add a new #{IO.ANSI.bright()}live_reload pattern#{IO.ANSI.reset()} to your endpoint in #{IO.ANSI.bright()}config/dev.exs#{IO.ANSI.reset()}:

        config #{inspect(app_name)}, #{web_module}.Endpoint,
          live_reload: [
            patterns: [
              ...
              #{IO.ANSI.bright()}~r"storybook/.*(exs)$"#{IO.ANSI.reset()}
            ]
          ]
    """)
  end

  defp print_formatter_instructions(_web_module, _app_name, _opts) do
    print_instructions("""
      Add your storybook content to #{IO.ANSI.bright()}.formatter.exs#{IO.ANSI.reset()}

        [
          import_deps: [...],
          inputs: [
            ...
            #{IO.ANSI.bright()}"storybook/**/*.exs"#{IO.ANSI.reset()}
          ]
        ]
    """)
  end

  defp print_mixexs_instructions(_web_module, _app_name, _opts = [tailwind: false]), do: true

  defp print_mixexs_instructions(_web_module, _app_name, _opts) do
    print_instructions("""
      Add an alias to #{IO.ANSI.bright()}mix.exs#{IO.ANSI.reset()}

      defp aliases do
        [
          ...,
          "assets.deploy": [
            ...
            #{IO.ANSI.bright()}"tailwind storybook --minify",#{IO.ANSI.reset()}
            "phx.digest"
          ]
        ]
      end
    """)
  end

  defp print_docker_instructions(_web_module, _app_name, _opts) do
    print_instructions("""
      Add a COPY directive in #{IO.ANSI.bright()}Dockerfile#{IO.ANSI.reset()}

      COPY priv priv
      COPY lib lib
      COPY assets assets
      #{IO.ANSI.bright()}COPY storybook storybook#{IO.ANSI.reset()}
    """)
  end

  defp print_instructions(message) do
    Mix.shell().yes?(
      "#{IO.ANSI.green()}* manual setup instructions:#{IO.ANSI.reset()}\n#{message}\n\n#{IO.ANSI.bright()}[Y to continue]#{IO.ANSI.reset()}"
    )
  end
end
