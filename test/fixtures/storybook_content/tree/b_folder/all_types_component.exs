defmodule TreeStorybook.BFolder.AllTypesComponent do
  use PhxLiveStorybook.Entry, :component
  def function, do: &AllTypesComponent.all_types_component/1
  def name, do: "AllTypesComponent (b_folder)"
  def description, do: "All types component description"

  def attributes do
    [
      %Attr{id: :label, type: :string, doc: "A label", required: true},
      %Attr{id: :option, type: :atom, doc: "An option", options: [:opt1, :opt2, :opt3]},
      %Attr{id: :index_i, type: :integer, default: 42},
      %Attr{id: :index_i_with_range, type: :integer, options: 1..10, default: 5},
      %Attr{id: :index_f, type: :float},
      %Attr{id: :toggle, type: :boolean, default: false},
      %Attr{id: :things, type: :list},
      %Attr{id: :struct, type: AllTypesComponent.Struct},
      %Attr{id: :map, type: :map},
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
      },
      %Story{
        id: :with_struct,
        attributes: %{
          label: "foo",
          struct: %AllTypesComponent.Struct{name: "bar"}
        },
        block: "<p>inner block</p>"
      }
    ]
  end
end
