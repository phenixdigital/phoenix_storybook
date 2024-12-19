defmodule TreeStorybook.Component do
  use PhoenixStorybook.Story, :component
  def function, do: &Component.component/1

  def attributes do
    [
      %Attr{
        id: :id,
        type: :string
      },
      %Attr{
        id: :label,
        type: :string,
        doc: "component label",
        required: true
      },
      %Attr{
        id: :theme,
        type: :atom
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :hello,
        description: "Hello variation",
        attributes: %{label: "hello"}
      },
      %Variation{
        id: :world,
        description: "World variation",
        attributes: %{label: "world", index: 37}
      },
      %Variation{
        id: :lengthy,
        description: "Lengthy variation",
        attributes: %{
          label: "Omnis rerum facere aspernatur ipsum velit et illum in earum quia modi molestias qui sunt.",
          index: 37
        }
      },

      %Variation{
        id: :themed,
        description: "With a theme attribute",
        attributes: %{label: "world", theme: :blue}
      }
    ]
  end
end
