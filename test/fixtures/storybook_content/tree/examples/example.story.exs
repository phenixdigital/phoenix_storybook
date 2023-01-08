defmodule TreeStorybook.Examples.Example do
  use PhxLiveStorybook.Story, :example

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
