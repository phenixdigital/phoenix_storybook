defmodule TreeStorybook.BFolder.WithIdComponent do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1

  def attributes do
    [
      %Attr{id: :id, type: :string, required: true},
    ]
  end

  def variations do
    [
      %Variation{id: :default}
    ]
  end
end
