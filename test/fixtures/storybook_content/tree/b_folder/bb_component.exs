defmodule TreeStorybook.BFolder.BbComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &CComponent.c_component/1

  def description, do: "Bb component description"

  def attributes do
    [
      %Attr{id: :label, type: :string, doc: "A label", required: true},
      %Attr{id: :option, type: :atom, doc: "An option", options: [:opt1, :opt2, :opt3]},
      %Attr{id: :index_i, type: :integer, default: 42},
      %Attr{id: :index_i_with_range, type: :integer, options: 1..10, default: 5},
      %Attr{id: :index_f, type: :float},
      %Attr{id: :toggle, type: :boolean, default: false},
      %Attr{id: :things, type: :list},
      %Attr{id: :struct, type: CComponent.Struct},
      %Attr{id: :block, type: :block, doc: "Your inner block", required: true},
      %Attr{id: :slot_thing, type: :slot, doc: "Some slots"}
    ]
  end

  def stories do
    [
      %Story{
        id: :default,
        attributes: %{
          label: "default label",
          toggle: false
        },
        block: "<p>will be displayed in inner block</p>",
        slots: [
          "<:slot_thing>slot 1</:slot_thing>",
          "<:slot_thing>slot 2</:slot_thing>",
          "<:other_slot>not displayed</:other_slot>"
        ]
      }
    ]
  end
end
