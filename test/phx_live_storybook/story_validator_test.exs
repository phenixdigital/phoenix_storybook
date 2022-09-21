defmodule PhxLiveStorybook.StoryValidatorTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.{Attr, ComponentStory, Variation, VariationGroup}
  alias PhxLiveStorybook.StoryValidator

  defmodule MyModuleStruct, do: defstruct([])

  describe "component story base attributes" do
    test "with proper types it wont raise" do
      story = %ComponentStory{name: "name", description: "description", icon: "icon"}
      assert validate(story)
    end

    test "with invalid types it will raise" do
      story = %ComponentStory{name: :name}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story name must be a binary"

      story = %ComponentStory{description: :description}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story description must be a binary"

      story = %ComponentStory{icon: :icon}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story icon must be a binary"
    end
  end

  describe "story's component is a module" do
    test "with proper type it wont raise" do
      story = %ComponentStory{component: MyComponent}
      assert validate(story)
    end

    test "with invalit type it will raise" do
      story = %ComponentStory{component: "my_component"}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story component must be a module"
    end
  end

  describe "story's function is a function" do
    test "with proper type it wont raise" do
      story = %ComponentStory{function: & &1}
      assert validate(story)
    end

    test "with invalid type it will raise" do
      story = %ComponentStory{function: "my function"}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story function must be a function"
    end
  end

  describe "story's aliases is a list of atoms" do
    test "with proper aliases it wont raise" do
      story = %ComponentStory{aliases: []}
      assert validate(story)

      story = %ComponentStory{aliases: [Foo, Bar]}
      assert validate(story)
    end

    test "with invalid types it will raise" do
      story = %ComponentStory{aliases: ["Foo", "Bar"]}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story aliases must be a list of atoms"
    end
  end

  describe "story's imports is valid" do
    test "with proper imports it wont raise" do
      story = %ComponentStory{imports: []}
      assert validate(story)

      story = %ComponentStory{imports: [{Foo, fun: 0, fun: 1}, {Bar, fun: 0, fun: 1}]}
      assert validate(story)
    end

    test "with invalid imports it will raise" do
      story = %ComponentStory{imports: [Foo, Bar]}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story imports must be a list of {atom, [{atom, integer}]}"

      story = %ComponentStory{imports: [{Foo, [:fun]}]}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story imports must be a list of {atom, [{atom, integer}]}"
    end
  end

  describe "story's container is either :div or :iframe" do
    test "with proper type it wont raise" do
      story = %ComponentStory{container: :div}
      assert validate(story)

      story = %ComponentStory{container: :iframe}
      assert validate(story)
    end

    test "with invalid value it will raise" do
      story = %ComponentStory{container: :span}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story container must be either :div or :iframe"

      story = %ComponentStory{container: "iframe"}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story container must be either :div or :iframe"
    end
  end

  describe "story template" do
    test "with proper type it wont raise" do
      story = %ComponentStory{template: nil}
      assert validate(story)

      story = %ComponentStory{template: "<div><.lsb-variation/></div>"}
      assert validate(story)
    end

    test "with invalid value it will raise" do
      story = %ComponentStory{template: :invalid}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story template must be a binary"
    end
  end

  describe "variation template" do
    test "with proper type it wont raise" do
      story = %ComponentStory{variations: [%Variation{id: :foo, template: nil}]}
      assert validate(story)

      story = %ComponentStory{variations: [%Variation{id: :foo, template: false}]}
      assert validate(story)

      story = %ComponentStory{
        variations: [%Variation{id: :foo, template: "<div><.lsb-variation/></div>"}]
      }

      assert validate(story)
    end

    test "with invalid value it will raise" do
      story = %ComponentStory{
        variations: [%Variation{id: :foo, template: :invalid}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "template in variation :foo must be a binary"
    end
  end

  describe "variation_group template is a string" do
    test "with proper type it wont raise" do
      story = %ComponentStory{
        variations: [%VariationGroup{id: :foo, variations: [], template: nil}]
      }

      assert validate(story)

      story = %ComponentStory{
        variations: [
          %VariationGroup{id: :foo, variations: [], template: "<div><.lsb-variation/></div>"}
        ]
      }

      assert validate(story)
    end

    test "with invalid value it will raise" do
      story = %ComponentStory{
        variations: [%VariationGroup{id: :foo, variations: [], template: :invalid}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "template in variation_group :foo must be a binary"
    end

    test "cannot set template on a variation in a group" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{
            id: :group,
            variations: [%Variation{id: :foo, template: "<div><.lsb-variation/></div>"}]
          }
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               "template in a group variation cannot be set (variation :foo, group :group)"
    end
  end

  describe "story attributes are list of Attrs" do
    test "with proper attr type it wont raise" do
      story = %ComponentStory{attributes: [%Attr{id: :foo, type: :string}]}
      assert validate(story)
    end

    test "with empty list it wont raise" do
      story = %ComponentStory{attributes: []}
      assert validate(story)
    end

    test "with invalid type it will raise" do
      story = %ComponentStory{attributes: [:foo]}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "story attributes must be a list of %Attr{}"
    end
  end

  describe "attributes ids" do
    test "atom id wont raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :foo, type: :string}]
      }

      assert validate(story)
    end

    test "invalid id will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: "foo", type: :string}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "id for attribute \"foo\" must be an atom"
    end

    test "unique attribute ids wont raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :foo, type: :string},
          %Attr{id: :bar, type: :integer},
          %Attr{id: :qix, type: :integer}
        ]
      }

      assert validate(story)
    end

    test "duplicate attribute ids will raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :foo, type: :string},
          %Attr{id: :bar, type: :integer},
          %Attr{id: :foo, type: :integer}
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "duplicate attribute id: :foo"
    end
  end

  describe "attributes types" do
    test "valid attribute types wont raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :any, type: :any},
          %Attr{id: :string, type: :string},
          %Attr{id: :atom, type: :atom},
          %Attr{id: :boolean, type: :boolean},
          %Attr{id: :integer, type: :integer},
          %Attr{id: :float, type: :float},
          %Attr{id: :list, type: :list},
          %Attr{id: :block, type: :block},
          %Attr{id: :slot, type: :slot}
        ]
      }

      assert validate(story)
    end

    test "valid atom types wont raise" do
      story = story_with_attr(id: :custom_struct, type: MyModuleStruct)
      assert validate(story)
    end

    test "invalid atom types will raise" do
      story = story_with_attr(id: :wrong, type: :wrong_type)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type :wrong_type for attr :wrong"
    end

    test "non atom types will raise" do
      story = story_with_attr(id: :wrong, type: "wrong_type")
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type \"wrong_type\" for attr :wrong"
    end
  end

  describe "attribute doc" do
    test "nil doc wont raise" do
      story = story_with_attr(type: :string, doc: nil)
      assert validate(story)
    end

    test "binary doc wont raise" do
      story = story_with_attr(type: :string, doc: "some documentation")
      assert validate(story)
    end

    test "invalid doc will raise" do
      story = story_with_attr(id: :foo, type: :string, doc: 'wrong_doc')
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "doc for attr :foo is not a binary"
    end
  end

  describe "attribute type and default do match" do
    test "with correct defaults, it wont raise" do
      story = story_with_attr(type: :integer, default: nil)
      assert validate(story)

      story = story_with_attr(type: :atom, default: :foo)
      assert validate(story)

      story = story_with_attr(type: :string, default: "foo")
      assert validate(story)

      story = story_with_attr(type: :boolean, default: false)
      assert validate(story)

      story = story_with_attr(type: :integer, default: 12)
      assert validate(story)

      story = story_with_attr(type: :float, default: 12.0)
      assert validate(story)

      story = story_with_attr(type: :list, default: [:foo])
      assert validate(story)

      story = story_with_attr(type: :any, default: "foo")
      assert validate(story)

      story = story_with_attr(type: :any, default: 12.0)
      assert validate(story)

      story = story_with_attr(type: :block, default: "<block/>")
      assert validate(story)

      story = story_with_attr(type: :slot, default: "<:slot/>")
      assert validate(story)

      story = story_with_attr(type: MyModuleStruct, default: %MyModuleStruct{})
      assert validate(story)
    end

    test "with incorrect defaults, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, default: "foo")
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type on default \"foo\" for attr :attr of type :atom"

      story = story_with_attr(id: :attr, type: :string, default: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :string"

      story = story_with_attr(id: :attr, type: :integer, default: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :integer"

      story = story_with_attr(id: :attr, type: :float, default: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :float"

      story = story_with_attr(id: :attr, type: :list, default: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :list"

      story = story_with_attr(id: :attr, type: MyModuleStruct, default: :foo)
      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               ~r/invalid type on default :foo for attr :attr of type .*MyModuleStruct/
    end
  end

  describe "attribute required must be a boolean" do
    test "with required true, it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, required: true)
      assert validate(story)
    end

    test "with required 'true', it will raise" do
      story = story_with_attr(id: :attr, type: :atom, required: 'true')
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required for attr :attr must be of type :boolean"
    end
  end

  describe "attribute cannot be required and provide default at the same time" do
    test "with required true and a default, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, default: :foo, required: true)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "only one of :required or :default must be given for attr :attr"
    end

    test "with required true and no default, it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, required: true)
      assert validate(story)
    end

    test "with required false and a default, it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, default: :foo, required: false)
      assert validate(story)
    end
  end

  describe "attribute examples is a list and is matching declared type" do
    test "with an empty list it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, examples: [])
      assert validate(story)
    end

    test "with a list of matching type, it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, examples: [:foo, :bar])
      assert validate(story)
    end

    test "with a list of integer and a range, it wont raise" do
      story = story_with_attr(id: :attr, type: :integer, examples: 1..10)
      assert validate(story)
    end

    test "without a list, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, examples: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "examples for attr :attr must be a list of :atom"
    end

    test "with a list of non matching type, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, examples: ["foo", "bar"])
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "examples for attr :attr must be a list of :atom"
    end
  end

  describe "attribute values is a list and is matching declared type" do
    test "with an empty list it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, values: [])
      assert validate(story)
    end

    test "with a list of matching type, it wont raise" do
      story = story_with_attr(id: :attr, type: :atom, values: [:foo, :bar])
      assert validate(story)
    end

    test "with a list of integer and a range, it wont raise" do
      story = story_with_attr(id: :attr, type: :integer, values: 1..10)
      assert validate(story)
    end

    test "without a list, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, values: :foo)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "values for attr :attr must be a list of :atom"
    end

    test "with a list of non matching type, it will raise" do
      story = story_with_attr(id: :attr, type: :atom, values: ["foo", "bar"])
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "values for attr :attr must be a list of :atom"
    end
  end

  describe "attribute examples & values cant be set at the same time" do
    test "it raises" do
      story =
        story_with_attr(id: :attr, type: :atom, examples: [:foo, :var], values: [:foo, :bar])

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "examples and values for attr :attr cannot be set at the same time"
    end
  end

  describe "attribute block unicity" do
    test "with a single block it wont raise" do
      story = story_with_attr(id: :block, type: :block)
      assert validate(story)
    end

    test "with two blocks it will raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :block_1, type: :block},
          %Attr{id: :block_2, type: :block}
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "at most a single block attribute can be declared"
    end
  end

  describe "variations id" do
    test "atom id wont raise" do
      story = story_with_variation(id: :foo)
      assert validate(story)
    end

    test "invalid id will raise" do
      story = story_with_variation(id: "foo")

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "id for variation \"foo\" must be an atom"
    end

    test "unique variation ids wont raise" do
      story = %ComponentStory{
        variations: [
          %Variation{id: :foo},
          %Variation{id: :bar},
          %Variation{id: :qix}
        ]
      }

      assert validate(story)
    end

    test "duplicate variation ids will raise" do
      story = %ComponentStory{
        variations: [
          %Variation{id: :foo},
          %Variation{id: :bar},
          %Variation{id: :foo}
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "duplicate variation id: :foo"
    end

    test "duplicate variation ids accross 2 groups wont raise" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{id: :group_1, variations: [%Variation{id: :foo}]},
          %VariationGroup{id: :group_2, variations: [%Variation{id: :foo}]}
        ]
      }

      assert validate(story)
    end

    test "duplicate variation ids in same group will raise" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{id: :group_1, variations: [%Variation{id: :foo}, %Variation{id: :foo}]},
          %VariationGroup{id: :group_2, variations: [%Variation{id: :bar}]}
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "duplicate variation id: :foo in group :group_1"
    end
  end

  describe "variation description is a binary" do
    test "with a binary description it wont raise" do
      story = story_with_variation(id: :variation_id, description: "valid")
      assert validate(story)
    end

    test "with a binary description in a variation group, it wont raise" do
      story = story_with_variation_in_group(:group_id, id: :variation_id, description: "valid")
      assert validate(story)
    end

    test "with invalid type it will raise" do
      story = story_with_variation(id: :variation_id, description: :not_valid)
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "description in variation :variation_id must be a binary"
    end

    test "with invalid type in a variation group it will raise" do
      story = story_with_variation_in_group(:group_id, id: :variation_id, description: :not_valid)
      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               "description in variation :variation_id, group :group_id must be a binary"
    end
  end

  describe "variation let is an atom" do
    test "with an atom let it wont raise" do
      story = story_with_variation(id: :variation_id, let: :valid)
      assert validate(story)
    end

    test "with an atom let in a variation group, it wont raise" do
      story = story_with_variation_in_group(:group_id, id: :variation_id, let: :valid)
      assert validate(story)
    end

    test "with invalid type it will raise" do
      story = story_with_variation(id: :variation_id, let: "not_valid")
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "let in variation :variation_id must be an atom"
    end

    test "with invalid type in a variation group it will raise" do
      story = story_with_variation_in_group(:group_id, id: :variation_id, let: "not_valid")
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "let in variation :variation_id, group :group_id must be an atom"
    end
  end

  describe "variation list is a list of %Variation{} or %VariationGroup{}" do
    test "with a mix of variation and variation_group it won't raise" do
      story = %ComponentStory{
        variations: [
          %Variation{id: :foo},
          %VariationGroup{id: :group_1, variations: []}
        ]
      }

      assert validate(story)
    end

    test "with an empty list it won't raise" do
      story = %ComponentStory{variations: []}
      assert validate(story)
    end

    test "with an invalid type it will raise" do
      story = %ComponentStory{variations: %Variation{id: :foo}}
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "variations must be a list of %Variation{} or %VariationGroup{}"
    end
  end

  describe "variation list in a group is a list of %Variation{}" do
    test "with a list of variations it won't raise" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{
            id: :group_1,
            variations: [%Variation{id: :variation_1}, %Variation{id: :variation_2}]
          }
        ]
      }

      assert validate(story)
    end

    test "with an empty list it won't raise" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{id: :group_1, variations: []}
        ]
      }

      assert validate(story)
    end

    test "with a nested %VariationGroup{} it will raise" do
      story = %ComponentStory{
        variations: [
          %VariationGroup{
            id: :group_1,
            variations: [%VariationGroup{id: :nested_group, variations: []}]
          }
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "variations in group :group_1 must be a list of %Variation{}"
    end
  end

  describe "variation attributes is a map" do
    test "with a map it won't raise" do
      story = story_with_variation(attributes: %{})
      assert validate(story)
    end

    test "with a list it will raise" do
      story = story_with_variation(id: :variation_id, attributes: [])
      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "attributes in variation :variation_id must be a map"
    end
  end

  describe "nested variation attributes is a map" do
    test "with a map it won't raise" do
      story = story_with_variation_in_group(:group_id, attributes: %{})
      assert validate(story)
    end

    test "with a list it will raise" do
      story = story_with_variation_in_group(:group_id, id: :variation_id, attributes: [])
      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               "attributes in variation :variation_id, group :group_id must be a map"
    end
  end

  describe "variation attributes match with their definition" do
    test "variation attribute without definition wont raise" do
      story = %ComponentStory{
        variations: [
          %Variation{id: :foo, attributes: %{foo: "bar"}},
          %VariationGroup{
            id: :group_1,
            variations: [%Variation{id: :foo, attributes: %{foo: "bar"}}]
          }
        ]
      }

      assert validate(story)
    end

    test "variation attribute with correct definition wont raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :foo, type: :atom},
          %Attr{id: :bar, type: :integer}
        ],
        variations: [
          %Variation{id: :foo, attributes: %{foo: :bar}},
          %VariationGroup{
            id: :group_1,
            variations: [%Variation{id: :foo, attributes: %{bar: 12}}]
          }
        ]
      }

      assert validate(story)
    end

    test "variation attribute with invalid definition will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :bar, type: :atom}],
        variations: [%Variation{id: :foo, attributes: %{bar: "bar"}}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "attribute :bar in variation :foo must be of type: :atom"

      story = %ComponentStory{
        attributes: [%Attr{id: :bar, type: :atom}],
        variations: [
          %VariationGroup{
            id: :group,
            variations: [%Variation{id: :foo, attributes: %{bar: "bar"}}]
          }
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               "attribute :bar in variation :foo, group :group must be of type: :atom"
    end

    test "variation attribute value matching attribute values wont raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :attr, type: :atom, values: [:foo, :bar]}],
        variations: [%Variation{id: :foo, attributes: %{attr: :bar}}]
      }

      assert validate(story)
    end

    test "variation attribute value don't matching attribute values will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :attr, type: :atom, values: [:foo, :bar]}],
        variations: [%Variation{id: :foo, attributes: %{attr: :not_matching}}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "attribute :attr in variation :foo must be one of [:foo, :bar]"
    end

    test "variation group attribute value don't matching attribute values will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :attr, type: :atom, values: [:foo, :bar]}],
        variations: [
          %VariationGroup{
            id: :group,
            variations: [%Variation{id: :foo, attributes: %{attr: :not_matching}}]
          }
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end

      assert e.description =~
               "attribute :attr in variation :foo, group :group must be one of [:foo, :bar]"
    end

    test "variation attribute value don't matching attribute examples won't raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :attr, type: :atom, examples: [:foo, :bar]}],
        variations: [%Variation{id: :foo, attributes: %{attr: :not_matching}}]
      }

      assert validate(story)
    end

    test "variation with invalid block type will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :block, type: :block}],
        variations: [%Variation{id: :variation, block: :not_a_block}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "block in variation :variation must be a binary"
    end

    test "variation with invalid slot type will raise" do
      story = %ComponentStory{
        variations: [%Variation{id: :variation, slots: [:not_a_slot]}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "slots in variation :variation must be a list of binary"
    end
  end

  describe "required variation attributes" do
    test "variation with all required attributes wont raise" do
      story = %ComponentStory{
        attributes: [
          %Attr{id: :foo, type: :atom, required: true},
          %Attr{id: :bar, type: :integer, required: true}
        ],
        variations: [
          %Variation{id: :foo, attributes: %{foo: :bar, bar: 12}},
          %VariationGroup{
            id: :group_1,
            variations: [%Variation{id: :foo, attributes: %{foo: :bar, bar: 12}}]
          }
        ]
      }

      assert validate(story)
    end

    test "variation with missing required attributes will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :bar, type: :atom, required: true}],
        variations: [%Variation{id: :foo, attributes: %{}}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required attribute :bar missing from variation :foo"

      story = %ComponentStory{
        attributes: [%Attr{id: :bar, type: :atom, required: true}],
        variations: [
          %VariationGroup{id: :group, variations: [%Variation{id: :foo, attributes: %{}}]}
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required attribute :bar missing from variation :foo, group :group"
    end

    test "variation with required block wont raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :block, type: :block, required: true}],
        variations: [%Variation{id: :foo, block: "provided"}]
      }

      assert validate(story)
    end

    test "variation without required block will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :block, type: :block, required: true}],
        variations: [%Variation{id: :foo}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required block missing from variation :foo"
    end

    test "nested variation without required block will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :block, type: :block, required: true}],
        variations: [%VariationGroup{id: :group, variations: [%Variation{id: :foo}]}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required block missing from variation :foo, group :group"
    end

    test "variation with required slot wont raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :slot, type: :slot, required: true}],
        variations: [%Variation{id: :foo, slots: ["<:slot>provided</:slot>"]}]
      }

      assert validate(story)
    end

    test "variation without required slot will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :slot, type: :slot, required: true}],
        variations: [%Variation{id: :foo}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required slot :slot missing from variation :foo"

      story = %ComponentStory{
        attributes: [%Attr{id: :slot, type: :slot, required: true}],
        variations: [%Variation{id: :foo, slots: ["<:wrong_slot>provided</:wrong_slot>"]}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required slot :slot missing from variation :foo"
    end

    test "nested variation without required slot will raise" do
      story = %ComponentStory{
        attributes: [%Attr{id: :slot, type: :slot, required: true}],
        variations: [%VariationGroup{id: :group, variations: [%Variation{id: :foo}]}]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required slot :slot missing from variation :foo, group :group"

      story = %ComponentStory{
        attributes: [%Attr{id: :slot, type: :slot, required: true}],
        variations: [
          %VariationGroup{
            id: :group,
            variations: [%Variation{id: :foo, slots: ["<:wrong_slot>provided</:wrong_slot>"]}]
          }
        ]
      }

      e = assert_raise CompileError, fn -> validate(story) end
      assert e.description =~ "required slot :slot missing from variation :foo, group :group"
    end
  end

  defp story_with_attr(opts) do
    %ComponentStory{
      attributes: [
        %Attr{
          id: opts[:id] || opts[:type],
          type: opts[:type],
          doc: opts[:doc],
          default: opts[:default],
          required: opts[:required],
          examples: opts[:examples],
          values: opts[:values]
        }
      ]
    }
  end

  defp story_with_variation(opts) do
    %ComponentStory{
      variations: [
        %Variation{
          id: opts[:id],
          let: opts[:let],
          description: opts[:description],
          attributes: opts[:attributes] || %{}
        }
      ]
    }
  end

  defp story_with_variation_in_group(group_id, opts) do
    %ComponentStory{
      variations: [
        %VariationGroup{
          id: group_id,
          variations: [
            %Variation{
              id: opts[:id],
              let: opts[:let],
              description: opts[:description],
              attributes: opts[:attributes] || %{}
            }
          ]
        }
      ]
    }
  end

  defp validate(story) do
    %ComponentStory{} = StoryValidator.validate!(story)
  end
end
