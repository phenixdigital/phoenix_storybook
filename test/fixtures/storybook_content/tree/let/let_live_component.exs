defmodule TreeStorybook.Let.LetLiveComponent do
  use PhxLiveStorybook.Entry, :live_component
  def component, do: LetLiveComponent

  def stories do
    [
      %Story{
        id: :default,
        attributes: %{entries: ~w(foo bar qix)},
        let: :entry,
        block: "**<%= entry %>**"
      }
    ]
  end
end
