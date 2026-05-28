defmodule TreeStorybook.Examples.Iframe do
  use PhoenixStorybook.Story, :example

  def doc, do: "Iframe example story"
  def container, do: :iframe

  @impl true
  def render(assigns) do
    ~H"""
    <div id="iframe-example-story">
      Iframe example content
    </div>
    """
  end
end
