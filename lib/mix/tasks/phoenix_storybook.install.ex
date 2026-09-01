if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PhoenixStorybook.Install do
    @shortdoc "Installs PhoenixStorybook into a Phoenix application"

    @moduledoc """
    #{@shortdoc}

    Generates the storybook scaffolding (the same files as `mix phx.gen.storybook`)
    and applies the whole manual setup automatically:

      * a storybook backend in `lib/my_app_web/storybook.ex`
      * storybook assets in `assets/js/storybook.js` and `assets/css/storybook.css`
        (copied from your `app.css` so components render the same in the storybook)
      * example stories in `storybook/` for your core components
      * router: `import PhoenixStorybook.Router`, `storybook_assets()` and `live_storybook/2`
      * the CSS sandbox class on the `<body>` of your root layout
      * `config.exs`: `js/storybook.js` esbuild entry point and a `:storybook` tailwind profile
      * `dev.exs`: a tailwind watcher and a live_reload pattern for stories
      * `.formatter.exs`: `:phoenix_storybook` import and `storybook/**/*.exs` inputs
      * `mix.exs`: storybook tailwind build in the `assets.build` and `assets.deploy` aliases

    ## Example

    ```bash
    mix igniter.install phoenix_storybook
    ```

    ## Options

    * `--no-tailwind` - skip the TailwindCSS specific setup
    """

    use Igniter.Mix.Task

    alias Igniter.Code
    alias Igniter.Code.Common
    alias Igniter.Libs.Phoenix
    alias Igniter.Project
    alias Sourceror.Zipper

    @templates_folder "priv/templates/phx.gen.storybook"
    @example_story_functions ~w(button header table input simple_form)a

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_storybook,
        example: "mix igniter.install phoenix_storybook",
        schema: [tailwind: :boolean],
        defaults: [tailwind: true]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      if Mix.Project.umbrella?() do
        Igniter.add_issue(igniter, """
        umbrella projects are not supported.
        mix phoenix_storybook.install must be invoked from within your *_web application root directory
        """)
      else
        tailwind? = igniter.args.options[:tailwind] != false
        schema = build_schema(igniter)

        {igniter, router} =
          Phoenix.select_router(
            igniter,
            "Which router should the storybook be added to?"
          )

        {igniter, endpoint} =
          if router do
            Phoenix.select_endpoint(
              igniter,
              router,
              "Which endpoint should the storybook watchers be added to?"
            )
          else
            {igniter, nil}
          end

        igniter
        |> generate_files(schema, tailwind?)
        |> setup_router(router, schema)
        |> setup_sandbox_class(schema)
        |> setup_esbuild(schema)
        |> setup_tailwind(schema, tailwind?)
        |> setup_watcher(endpoint, schema, tailwind?)
        |> setup_live_reload(endpoint, schema)
        |> setup_formatter()
        |> setup_aliases(tailwind?)
        |> add_notices(schema, tailwind?)
      end
    end

    defp build_schema(igniter) do
      app_name = Project.Application.app_name(igniter)
      web_module = Phoenix.web_module(igniter)
      core_components_module = Module.concat(web_module, CoreComponents)

      %{
        app_name: app_name,
        web_app_name: web_module |> Macro.underscore() |> String.to_atom(),
        sandbox_class: String.replace(to_string(app_name), "_", "-"),
        web_module: web_module,
        web_module_name: inspect(web_module),
        core_components_module: core_components_module,
        core_components_module_name: inspect(core_components_module)
      }
    end

    ## FILES

    defp generate_files(igniter, schema, tailwind?) do
      {igniter, core_component_functions} =
        core_component_functions(igniter, schema.core_components_module)

      mapping =
        [
          {"storybook.ex.eex",
           Path.join(["lib", to_string(schema.web_app_name), "storybook.ex"])},
          {"_root.index.exs", "storybook/_root.index.exs"},
          {"welcome.story.exs", "storybook/welcome.story.exs"},
          {"storybook.js", "assets/js/storybook.js"}
        ] ++ core_components_mapping(core_component_functions)

      igniter =
        Enum.reduce(mapping, igniter, fn {source, target}, igniter ->
          source_path = Path.join(templates_folder(), source)

          contents =
            case Path.extname(source_path) do
              ".eex" -> EEx.eval_file(source_path, schema: schema)
              _ -> File.read!(source_path)
            end

          Igniter.create_new_file(igniter, target, contents, on_exists: :skip)
        end)

      generate_storybook_css(igniter, schema, tailwind?)
    end

    @app_css "assets/css/app.css"

    # PhoenixStorybook loads storybook.css instead of app.css, so the storybook
    # stylesheet starts as a copy of app.css: same plugins, themes and variants
    # mean components render the same in the storybook, and relative paths keep
    # working since both files live in assets/css. Falls back to a minimal
    # template when there is no app.css to copy (or with --no-tailwind).
    defp generate_storybook_css(igniter, schema, tailwind?) do
      {igniter, contents} =
        if tailwind? and Igniter.exists?(igniter, @app_css) do
          igniter = Igniter.include_existing_file(igniter, @app_css)

          app_css =
            igniter.rewrite |> Rewrite.source!(@app_css) |> Rewrite.Source.get(:content)

          {igniter, storybook_css_from_app_css(app_css)}
        else
          template = if tailwind?, do: "storybook.tailwind.css.eex", else: "storybook.css.eex"
          {igniter, EEx.eval_file(Path.join(templates_folder(), template), schema: schema)}
        end

      Igniter.create_new_file(igniter, "assets/css/storybook.css", contents, on_exists: :skip)
    end

    defp storybook_css_from_app_css(app_css) do
      """
      /*
       * Storybook stylesheet - copied from assets/css/app.css at install time.
       *
       * PhoenixStorybook does NOT load your app.css; it loads THIS file. When you
       * later change app.css (plugins, themes, custom variants, fonts, ...),
       * mirror the relevant changes here so your components render the same in
       * the storybook.
       */

      """ <>
        String.trim_trailing(app_css) <>
        """


        /* Pick up classes used in your stories */
        @source "../../storybook";
        """
    end

    defp templates_folder do
      Application.app_dir(:phoenix_storybook, @templates_folder)
    end

    defp core_component_functions(igniter, core_components_module) do
      case Project.Module.find_module(igniter, core_components_module) do
        {:ok, {igniter, _source, zipper}} ->
          functions =
            for function <- story_template_functions() ++ @example_story_functions,
                match?({:ok, _}, Code.Function.move_to_def(zipper, function, 1)),
                uniq: true do
              function
            end

          {igniter, functions}

        {:error, igniter} ->
          {igniter, nil}
      end
    end

    defp story_template_functions do
      templates_folder()
      |> Path.join("core_components/*.story.*")
      |> Path.wildcard()
      |> Enum.map(fn path ->
        path |> Path.basename() |> String.split(".") |> hd() |> String.to_atom()
      end)
    end

    defp core_components_mapping(nil), do: []

    defp core_components_mapping(functions) do
      stories =
        for function <- story_template_functions(), function in functions do
          {"core_components/#{function}.story.exs.eex",
           "storybook/core_components/#{function}.story.exs"}
        end

      index =
        [
          {"core_components/_core_components.index.exs.eex",
           "storybook/core_components/_core_components.index.exs"}
        ]

      example =
        if Enum.all?(@example_story_functions, &(&1 in functions)) do
          [
            {"examples/core_components.story.exs.eex",
             "storybook/examples/core_components.story.exs"}
          ]
        else
          []
        end

      stories ++ index ++ example
    end

    ## ROUTER

    defp setup_router(igniter, nil, schema) do
      Igniter.add_warning(igniter, """
      No Phoenix router found, please add the storybook to your router manually:

          use #{schema.web_module_name}, :router
          import PhoenixStorybook.Router

          scope "/" do
            storybook_assets()
          end

          scope "/", #{schema.web_module_name} do
            pipe_through(:browser)
            live_storybook("/storybook", backend_module: #{schema.web_module_name}.Storybook)
          end
      """)
    end

    defp setup_router(igniter, router, schema) do
      igniter
      |> add_router_import(router)
      |> add_assets_scope(router)
      |> add_storybook_route(router, schema)
    end

    defp add_router_import(igniter, router) do
      Project.Module.find_and_update_module!(igniter, router, fn zipper ->
        import_call =
          Code.Function.move_to_function_call_in_current_scope(
            zipper,
            :import,
            [1, 2],
            &Code.Function.argument_equals?(&1, 0, PhoenixStorybook.Router)
          )

        case import_call do
          {:ok, _zipper} ->
            {:ok, zipper}

          :error ->
            case Phoenix.move_to_router_use(igniter, zipper) do
              {:ok, zipper} ->
                {:ok, Common.add_code(zipper, "import PhoenixStorybook.Router")}

              :error ->
                {:warning,
                 "Could not add `import PhoenixStorybook.Router` to `#{inspect(router)}`. Please add it manually."}
            end
        end
      end)
    end

    defp add_assets_scope(igniter, router) do
      {igniter, defines?} = router_defines_call?(igniter, router, :storybook_assets, [0, 1])

      if defines? do
        igniter
      else
        Phoenix.add_scope(igniter, "/", "storybook_assets()", router: router)
      end
    end

    defp add_storybook_route(igniter, router, schema) do
      {igniter, defines?} = router_defines_call?(igniter, router, :live_storybook, [1, 2])

      if defines? do
        igniter
      else
        Phoenix.append_to_scope(
          igniter,
          "/",
          ~s|live_storybook("/storybook", backend_module: #{schema.web_module_name}.Storybook)|,
          router: router,
          arg2: schema.web_module,
          with_pipelines: [:browser],
          placement: :after
        )
      end
    end

    defp router_defines_call?(igniter, router, function, arities) do
      case Project.Module.find_module(igniter, router) do
        {:ok, {igniter, _source, zipper}} ->
          found? =
            match?(
              {:ok, _},
              Code.Function.move_to_function_call(zipper, function, arities)
            )

          {igniter, found?}

        {:error, igniter} ->
          {igniter, false}
      end
    end

    ## LAYOUT

    # Igniter cannot parse HEEx, so the root layout is patched as plain text,
    # and only when the <body> tag has an unambiguous static shape. Anything
    # else (dynamic class={...}, relocated layout, ...) falls back to a notice.
    defp setup_sandbox_class(igniter, schema) do
      path =
        Path.join([
          "lib",
          to_string(schema.web_app_name),
          "components",
          "layouts",
          "root.html.heex"
        ])

      if Igniter.exists?(igniter, path) do
        igniter = Igniter.include_existing_file(igniter, path)
        content = igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)

        case add_body_class(content, schema.sandbox_class) do
          {:ok, content} ->
            Igniter.update_file(igniter, path, &Rewrite.Source.update(&1, :content, content))

          :already ->
            igniter

          :error ->
            add_sandbox_notice(igniter, schema)
        end
      else
        add_sandbox_notice(igniter, schema)
      end
    end

    # Matches a <body> tag whose attributes are all static (`name` or
    # `name="value"`), so any dynamic attribute bails out to :error.
    @body_tag_regex ~r/<body((?:\s+[\w:@.-]+(?:="[^"<>{}]*")?)*)\s*>/

    defp add_body_class(content, class) do
      case Regex.run(@body_tag_regex, content) do
        nil ->
          :error

        [tag, attrs] ->
          case Regex.run(~r/class="([^"]*)"/, attrs) do
            nil ->
              new_tag = String.replace(tag, "<body", ~s|<body class="#{class}"|)
              {:ok, String.replace(content, tag, new_tag, global: false)}

            [_class_attr, classes] ->
              if class in String.split(classes) do
                :already
              else
                new_classes = String.trim("#{classes} #{class}")
                new_tag = String.replace(tag, ~s|class="#{classes}"|, ~s|class="#{new_classes}"|)
                {:ok, String.replace(content, tag, new_tag, global: false)}
              end
          end
      end
    end

    defp add_sandbox_notice(igniter, schema) do
      Igniter.add_notice(igniter, """
      Add the CSS sandbox class to your layout in lib/#{schema.web_app_name}/components/layouts/root.html.heex:

          <body class="#{schema.sandbox_class}">
      """)
    end

    ## CONFIG

    defp setup_esbuild(igniter, schema) do
      if Project.Config.configures_key?(
           igniter,
           "config.exs",
           :esbuild,
           [schema.app_name, :args]
         ) do
        igniter
        |> Project.Config.configure(
          "config.exs",
          :esbuild,
          [schema.app_name, :args],
          nil,
          updater: &add_esbuild_entry_point/1
        )
        |> notice_unless_esbuild_wired(schema)
      else
        Igniter.add_notice(igniter, esbuild_message(schema))
      end
    end

    # `Project.Config.configure/6` silently leaves the profile untouched when the
    # entry point can't be added automatically (e.g. a customized `args` with no
    # `js/app.js` to anchor on), so fall back to the manual notice in that case.
    defp notice_unless_esbuild_wired(igniter, schema) do
      igniter = Igniter.include_existing_file(igniter, "config/config.exs")

      content =
        igniter.rewrite |> Rewrite.source!("config/config.exs") |> Rewrite.Source.get(:content)

      if String.contains?(content, "js/storybook.js") do
        igniter
      else
        Igniter.add_notice(igniter, esbuild_message(schema))
      end
    end

    defp add_esbuild_entry_point(zipper) do
      case zipper.node do
        {:sigil_w, _, [{:<<>>, _, [args]}, _]} when is_binary(args) ->
          cond do
            String.contains?(args, "js/storybook.js") ->
              {:ok, zipper}

            String.contains?(args, "js/app.js") ->
              {:ok,
               Zipper.update(zipper, fn {:sigil_w, meta, [{:<<>>, args_meta, [args]}, modifiers]} ->
                 args = String.replace(args, "js/app.js", "js/app.js js/storybook.js")
                 {:sigil_w, meta, [{:<<>>, args_meta, [args]}, modifiers]}
               end)}

            true ->
              :error
          end

        _ ->
          :error
      end
    end

    defp esbuild_message(schema) do
      """
      Add js/storybook.js as a new entry point to your esbuild profile in config/config.exs:

          config :esbuild,
            #{schema.app_name}: [
              args: ~w(js/app.js js/storybook.js --bundle ...),
              ...
            ]
      """
    end

    defp setup_tailwind(igniter, _schema, false), do: igniter

    defp setup_tailwind(igniter, schema, true) do
      cond do
        # `configure_new/6` reformats an already set value, so don't even reach
        # for it when the storybook profile is already configured
        Project.Config.configures_key?(igniter, "config.exs", :tailwind, [:storybook]) ->
          igniter

        Project.Config.configures_key?(
          igniter,
          "config.exs",
          :tailwind,
          [schema.app_name]
        ) ->
          Project.Config.configure_new(
            igniter,
            "config.exs",
            :tailwind,
            [:storybook],
            {:code,
             Sourceror.parse_string!("""
             [
               args: ~w(
                   --input=assets/css/storybook.css
                   --output=priv/static/assets/css/storybook.css
                 ),
               cd: Path.expand("..", __DIR__)#{tailwind_env_kw(igniter, "  ")}
             ]
             """)}
          )

        true ->
          Igniter.add_notice(igniter, """
          Add a tailwind build profile for assets/css/storybook.css in config/config.exs:

              config :tailwind,
                storybook: [
                  args: ~w(
                    --input=assets/css/storybook.css
                    --output=priv/static/assets/css/storybook.css
                  ),
                  cd: Path.expand("..", __DIR__)#{tailwind_env_kw(igniter, "        ")}
                ]
          """)
      end
    end

    # LiveView >= 1.2 writes `@import "phoenix-colocated/..."` into app.css, which
    # we copy verbatim into storybook.css. Resolving that import needs a list-form
    # NODE_PATH on the tailwind profile, and that list form is only joined into a
    # path by tailwind >= 0.5.0 — which any app already using colocated CSS runs,
    # since its own main profile resolves the same import. Apps without the import
    # (older LiveView) get no env, so their older tailwind can't be handed a config
    # it would crash on. The leading comma lives here so `cd:` has no trailing one.
    defp tailwind_env_kw(igniter, indent) do
      if colocated_css?(igniter) do
        ",\n" <>
          indent <>
          ~S|env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}|
      else
        ""
      end
    end

    defp colocated_css?(igniter) do
      if Igniter.exists?(igniter, @app_css) do
        igniter = Igniter.include_existing_file(igniter, @app_css)

        igniter.rewrite
        |> Rewrite.source!(@app_css)
        |> Rewrite.Source.get(:content)
        |> String.contains?("phoenix-colocated")
      else
        false
      end
    end

    defp setup_watcher(igniter, _endpoint, _schema, false), do: igniter

    defp setup_watcher(igniter, nil, schema, true) do
      Igniter.add_notice(igniter, watcher_message(schema))
    end

    defp setup_watcher(igniter, endpoint, schema, true) do
      watchers =
        Sourceror.parse_string!(
          "[storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]}]"
        )

      {:__block__, _, [[watcher]]} = watchers

      Project.Config.configure(
        igniter,
        "dev.exs",
        schema.app_name,
        [endpoint, :watchers],
        {:code, watchers},
        updater: fn zipper ->
          case Code.Keyword.get_key(zipper, :storybook_tailwind) do
            {:ok, _} -> {:ok, zipper}
            :error -> Code.List.append_to_list(zipper, watcher)
          end
        end,
        failure_message: watcher_message(schema)
      )
    end

    defp watcher_message(schema) do
      """
      Add a watcher for the storybook tailwind profile to your endpoint in config/dev.exs:

          config #{inspect(schema.app_name)}, #{schema.web_module_name}.Endpoint,
            watchers: [
              ...
              storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]}
            ]
      """
    end

    defp setup_live_reload(igniter, nil, schema) do
      Igniter.add_notice(igniter, live_reload_message(schema))
    end

    # The endpoint live_reload configuration usually lives in its own `config`
    # call in dev.exs, so `Project.Config.configure/6` cannot be used
    # here: it would patch the first `config` call matching the app and
    # endpoint, which is usually the one holding the http settings and watchers.
    defp setup_live_reload(igniter, endpoint, schema) do
      if Igniter.exists?(igniter, "config/dev.exs") do
        Igniter.update_elixir_file(igniter, "config/dev.exs", fn zipper ->
          case add_live_reload_pattern(zipper, endpoint, schema.app_name) do
            {:ok, zipper} -> {:ok, zipper}
            :error -> {:warning, live_reload_message(schema)}
          end
        end)
      else
        Igniter.add_notice(igniter, live_reload_message(schema))
      end
    end

    defp add_live_reload_pattern(zipper, endpoint, app_name) do
      pattern = Sourceror.parse_string!(~S|~r"storybook/.*\.exs$"|)

      with {:ok, zipper} <- move_to_live_reload_config(zipper, endpoint, app_name),
           {:ok, zipper} <- Code.Function.move_to_nth_argument(zipper, 2) do
        Code.Keyword.put_in_keyword(zipper, [:live_reload, :patterns], nil, fn patterns ->
          if String.contains?(Sourceror.to_string(patterns.node), "storybook/.*") do
            {:ok, patterns}
          else
            Code.List.append_to_list(patterns, pattern)
          end
        end)
      end
    end

    defp move_to_live_reload_config(zipper, endpoint, app_name) do
      Code.Function.move_to_function_call_in_current_scope(zipper, :config, 3, fn call ->
        Code.Function.argument_equals?(call, 0, app_name) and
          Code.Function.argument_equals?(call, 1, endpoint) and
          Code.Function.argument_matches_predicate?(
            call,
            2,
            &Code.Keyword.keyword_has_path?(&1, [:live_reload, :patterns])
          )
      end)
    end

    defp live_reload_message(schema) do
      """
      Add a live_reload pattern to your endpoint in config/dev.exs to live reload your stories:

          config #{inspect(schema.app_name)}, #{schema.web_module_name}.Endpoint,
            live_reload: [
              patterns: [
                ...
                ~r"storybook/.*\\.exs$"
              ]
            ]
      """
    end

    ## FORMATTER

    defp setup_formatter(igniter) do
      igniter
      |> Project.Formatter.import_dep(:phoenix_storybook)
      |> Igniter.update_elixir_file(".formatter.exs", fn zipper ->
        input = "storybook/**/*.exs"

        case Zipper.down(zipper) do
          nil ->
            {:warning, formatter_message()}

          zipper ->
            zipper
            |> Zipper.rightmost()
            |> Code.Keyword.put_in_keyword([:inputs], [input], fn nested_zipper ->
              Code.List.append_new_to_list(nested_zipper, input)
            end)
            |> case do
              {:ok, zipper} -> {:ok, zipper}
              :error -> {:warning, formatter_message()}
            end
        end
      end)
    end

    defp formatter_message do
      """
      Add your stories to your formatter inputs in .formatter.exs:

          inputs: [
            ...
            "storybook/**/*.exs"
          ]
      """
    end

    ## MIX ALIASES

    defp setup_aliases(igniter, false), do: igniter

    defp setup_aliases(igniter, true) do
      igniter
      |> Project.TaskAliases.add_alias("assets.build", ["tailwind storybook"], if_exists: :append)
      |> Project.TaskAliases.add_alias(
        "assets.deploy",
        ["tailwind storybook --minify", "phx.digest"],
        if_exists: :ignore
      )
      |> Project.TaskAliases.modify_existing_alias(
        "assets.deploy",
        &add_to_assets_deploy/1
      )
    end

    defp add_to_assets_deploy(zipper) do
      build_task = "tailwind storybook --minify"

      with :error <-
             Code.List.move_to_list_item(zipper, &Common.nodes_equal?(&1, build_task)),
           {:ok, digest_zipper} <-
             Code.List.move_to_list_item(zipper, &Common.nodes_equal?(&1, "phx.digest")) do
        {:ok, Zipper.insert_left(digest_zipper, Sourceror.parse_string!(inspect(build_task)))}
      else
        {:ok, _already_present} -> {:ok, zipper}
        :error -> Code.List.append_new_to_list(zipper, build_task)
      end
    end

    ## NOTICES

    defp add_notices(igniter, schema, tailwind?) do
      igniter
      |> then(fn igniter ->
        cond do
          not tailwind? ->
            Igniter.add_notice(igniter, """
            You opted out of Tailwind, so no build step was added for your storybook
            stylesheet. Add a step to your asset pipeline that builds
            assets/css/storybook.css to priv/static/assets/css/storybook.css, plus a
            matching dev watcher, and register it in your assets.build and
            assets.deploy aliases (mix.exs).
            """)

          Igniter.exists?(igniter, @app_css) ->
            Igniter.add_notice(igniter, """
            assets/css/storybook.css was generated as a copy of your assets/css/app.css
            (plus a storybook @source directive), so your components render the same in
            the storybook. When you later change app.css, mirror the relevant changes
            there too.
            """)

          true ->
            Igniter.add_notice(igniter, """
            Review the generated assets/css/storybook.css:

            PhoenixStorybook loads this file instead of your app.css, so any @plugin,
            theme, @custom-variant or font you added to assets/css/app.css must be
            mirrored there too, or your components render unstyled. See the comments
            at the top of the generated file.
            """)
        end
      end)
      |> then(fn igniter ->
        if tailwind? do
          Igniter.add_notice(igniter, """
          (Optional) If you have your own scoped component CSS (not daisyUI/plugin
          classes), nest it under your CSS sandbox class in assets/css/storybook.css.
          Global @plugin / @custom-variant / theme directives must stay at the top level:

              .#{schema.sandbox_class} {
                h1, h2, h3 {
                  /* your custom component styling */
                }
              }
          """)
        else
          igniter
        end
      end)
      |> then(fn igniter ->
        if Igniter.exists?(igniter, "Dockerfile") or Igniter.exists?(igniter, "dockerfile") do
          Igniter.add_notice(igniter, """
          Add a COPY directive to your Dockerfile:

              COPY storybook storybook
          """)
        else
          igniter
        end
      end)
      |> Igniter.add_notice("""
      You are all set! 🚀
      You can run mix phx.server and visit http://localhost:4000/storybook
      """)
    end
  end
end
