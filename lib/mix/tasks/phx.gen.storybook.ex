defmodule Mix.Tasks.Phx.Gen.Storybook do
  @shortdoc "Generates a Storybook to showcase your LiveComponents"
  @moduledoc """
  Generates a Storybook.

      $ mix phx.gen.storybook

  The generated files will contain:

    * the storybook backend in `lib/my_app_web/storybook.ex`
    * a dummy component in `storybook/components/my_component.story.exs`
    * a dummy page in `storybook/my_app_web/my_page.story.exs`
    * your custom js in `assets/js/storybook.js`
    * your custom css in `assets/css/storybook.css`
  """

  use Mix.Task

  @templates_folder "priv/templates/phx.gen.storybook"

  @doc false
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix phx.gen.storybook must be invoked from within your *_web application root directory"
      )
    end

    Mix.shell().info("Starting Storybook generation")

    web_module = web_module()

    app_folder = Path.join("lib", Phoenix.Naming.underscore(web_module))
    component_folder = "storybook/components"
    page_folder = "storybook"
    js_folder = "assets/js"
    css_folder = "assets/css"

    schema = %{
      app: String.to_atom(Phoenix.Naming.underscore(web_module)),
      module: web_module
    }

    mapping = [
      {"storybook.ex", app_folder},
      {"my_component.story.exs", component_folder},
      {"my_page.story.exs", page_folder},
      {"storybook.js", js_folder},
      {"storybook.css", css_folder}
    ]

    for {source_file_path, target} <- mapping do
      root = Application.app_dir(:phx_live_storybook, @templates_folder)
      source = Path.join(root, source_file_path)

      Mix.Generator.create_file(
        Path.join(target, source_file_path),
        EEx.eval_file(source, schema: schema, assigns: [text: "<%=@text%>"])
      )
    end

    Mix.shell().info("""
    [warn]
    Add the following to your router.ex:

        use #{Module.split(web_module) |> List.last()}, :router
        import PhxLiveStorybook.Router
        ...
        scope "/" do
          storybook_assets()
        end

        scope "/", #{Module.split(web_module) |> List.last()} do
          pipe_through(:browser)
          ...
          live_storybook "/storybook", backend_module: #{Module.split(web_module) |> List.last()}.Storybook
        end
    """)
  end

  defp web_module do
    base = Mix.Phoenix.base()

    cond do
      Mix.Phoenix.context_app() != Mix.Phoenix.otp_app() ->
        Module.concat([base])

      String.ends_with?(base, "Web") ->
        Module.concat([base])

      true ->
        Module.concat(["#{base}Web"])
    end
  end
end
