defmodule TreeStorybook.Examples.DefaultContainer do
  use PhoenixStorybook.Story, :example

  def doc, do: "Default container example story"

  @impl true
  def render(assigns) do
    ~H"""
    <div id="default-container-example-story">
      Default container example content
    </div>
    """
  end
end
