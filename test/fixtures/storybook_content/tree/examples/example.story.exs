defmodule TreeStorybook.Examples.Example do
  use PhoenixStorybook.Story, :example

  def doc, do: "Example story"

  def extra_sources do
    [
      "./example_html.ex",
      "./templates/example.html.heex"
    ]
  end

  @impl true
  def render(assigns) do
    TreeStorybook.Examples.ExampleHTML.example(assigns)
  end
end
