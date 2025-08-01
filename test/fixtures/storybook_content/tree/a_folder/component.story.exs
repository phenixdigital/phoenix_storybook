defmodule TreeStorybook.AFolder.Component do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1
  def render_source, do: :function
  def container, do: {:div, class: "block", "data-foo": "bar"}

  def variations do
    [
      %VariationGroup{
        id: :group,
        note: "This group shows **different component options** with various attributes.",
        variations: [
          %Variation{
            id: :hello,
            description: "Hello variation",
            attributes: %{label: "hello"}
          },
          %Variation{
            id: :world,
            description: "World variation",
            attributes: %{label: "world", index: 37}
          }
        ]
      },
      %Variation{
        id: :no_attributes
      }
    ]
  end
end
