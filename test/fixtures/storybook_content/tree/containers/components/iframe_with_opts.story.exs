defmodule TreeStorybook.Containers.Components.IframeWithOpts do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1
  def container, do: {:iframe, "data-foo": "bar"}

  def variations do
    [
      %Variation{
        id: :hello
      }
    ]
  end
end
