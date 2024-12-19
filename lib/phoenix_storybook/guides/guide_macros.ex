defmodule PhoenixStorybook.Guides.Macros do
  @moduledoc false

  defmacro __using__(__opts \\ []) do
    if PhoenixStorybook.enabled?() do
      for path <- Path.wildcard(Path.expand("../../../guides/*.md", __DIR__)),
          guide = Path.basename(path),
          markdown = File.read!(path),
          {:ok, html_guide, _} = Earmark.as_html(markdown) do
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
