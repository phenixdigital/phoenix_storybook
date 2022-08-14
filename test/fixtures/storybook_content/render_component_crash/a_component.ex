defmodule RenderComponentCrashStorybook.AComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: nil

  def stories do
    [
      %Story{
        id: :story,
        attributes: %{}
      }
    ]
  end
end
