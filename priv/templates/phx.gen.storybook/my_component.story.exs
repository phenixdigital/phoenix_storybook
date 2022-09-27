defmodule Storybook.Components.MyComponent do
  use PhxLiveStorybook.Story, :component
  import Phoenix.LiveView.Helpers # remove this line once you import your component

  def function, do: &my_component/1

  # This is a dummy fonction that you should replace with your own component.
  def my_component(assigns) do
    ~H"<span><%=@text%></span>"
  end

  def attributes do
    [
      %Attr{id: :text, doc: "Set the text to display", type: :string}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          text: "Hello World"
        }
      },
      %Variation{
        id: :text_variation,
        attributes: %{
          text: "A text variation"
        }
      }
    ]
  end
end
