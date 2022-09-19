defmodule TreeStorybook.Let.LetComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &LetComponent.let_component/1

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
