defmodule TreeStorybook.Let.LetComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &LetComponent.let_component/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{stories: ~w(foo bar qix)},
        slots: ["<:my_slot :let={entry}>**<%= entry %>**</:my_slot>"]
      }
    ]
  end
end
