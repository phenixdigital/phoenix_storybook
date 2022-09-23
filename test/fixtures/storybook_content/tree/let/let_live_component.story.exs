defmodule TreeStorybook.Let.LetLiveComponent do
  use PhxLiveStorybook.Story, :live_component
  def component, do: LetLiveComponent

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{stories: ~w(foo bar qix)},
        let: :entry,
        slots: ["**<%= entry %>**"]
      }
    ]
  end
end
