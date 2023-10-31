defmodule TreeStorybook.Containers.Components.Iframe do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1
  def container, do: :iframe

  def variations do
    [
      %Variation{
        id: :hello
      }
    ]
  end
end
