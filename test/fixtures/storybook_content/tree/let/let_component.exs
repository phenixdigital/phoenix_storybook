defmodule TreeStorybook.Let.LetComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &LetComponent.let_component/1

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
