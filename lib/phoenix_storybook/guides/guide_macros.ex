defmodule PhoenixStorybook.Guides.Macros do
  @moduledoc false

  @mdex_options [render: [unsafe: true]]

  defmacro __using__(__opts \\ []) do
    if PhoenixStorybook.enabled?() do
      for path <- Path.wildcard(Path.expand("../../../guides/*.md", __DIR__)),
          guide = Path.basename(path),
          markdown = File.read!(path),
          html_guide = MDEx.to_html!(markdown, @mdex_options) do
        quote do
          @external_resource unquote(path)
          def markup(unquote(guide)) do
            unquote(html_guide)
          end
        end
      end
    end
  end
end
