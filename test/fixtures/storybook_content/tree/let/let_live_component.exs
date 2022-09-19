defmodule TreeStorybook.Let.LetLiveComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: LetLiveComponent

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{entries: ~w(foo bar qix)},
        let: :entry,
        block: "**<%= entry %>**"
      }
    ]
  end
end
