defmodule TreeStorybook.BFolder.AllTypesComponent do
  use PhxLiveStorybook.Story, :component
  def function, do: &AllTypesComponent.all_types_component/1
  def description, do: "All types component description"

  def attributes do
    [
      %Attr{id: :label, type: :string, doc: "A label", required: true},
      %Attr{id: :option, type: :atom, doc: "An option", examples: [:opt1, :opt2, :opt3]},
      %Attr{id: :enforced_option, type: :atom, doc: "An option", values: [:opt1, :opt2, :opt3]},
      %Attr{id: :index_i, type: :integer, default: 42},
      %Attr{id: :index_i_with_range, type: :integer, examples: 1..10, default: 5},
      %Attr{id: :index_i_with_enforced_range, type: :integer, values: 1..10, default: 5},
      %Attr{id: :index_f, type: :float},
      %Attr{id: :toggle, type: :boolean, default: false},
      %Attr{id: :things, type: :list},
      %Attr{id: :struct, type: AllTypesComponent.Struct},
      %Attr{id: :map, type: :map},
      %Attr{id: :rest, type: :global}
    ]
  end

  def slots do
    [
      %Slot{id: :inner_block, doc: "Your inner block", required: true},
      %Slot{id: :slot_thing, doc: "Some slots"}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          label: "default label",
          toggle: false,
          rest: %{:foo => "bar", "data-bar" => 42}
        },
        slots: [
          "<p>will be displayed in inner block</p>",
          "<:slot_thing>slot 1</:slot_thing>",
          "<:slot_thing>slot 2</:slot_thing>",
          "<:other_slot>not displayed</:other_slot>"
        ]
      },
      %Variation{
        id: :with_struct,
        attributes: %{
          label: "foo",
          struct: %AllTypesComponent.Struct{name: "bar"}
        },
        slots: [
          "<p>inner block</p>"
        ]
      }
    ]
  end
end
