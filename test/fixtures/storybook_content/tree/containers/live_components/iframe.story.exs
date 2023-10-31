defmodule TreeStorybook.Containers.LiveComponents.Iframe do
  use PhoenixStorybook.Story, :live_component
  def component, do: LiveComponent
  def container, do: :iframe

  def variations do
    [
      %Variation{
        id: :hello
      }
    ]
  end
end
