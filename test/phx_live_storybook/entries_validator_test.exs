defmodule PhxLiveStorybook.EntriesValidatorTest do
  use ExUnit.Case

  alias PhxLiveStorybook.{Attr, ComponentEntry, Story, StoryGroup}
  alias PhxLiveStorybook.EntriesValidator

  defmodule MyModuleStruct, do: defstruct([])

  describe "attributes ids" do
    test "atom id wont raise" do
      entry = %ComponentEntry{
        attributes: [%Attr{id: :foo, type: :string}]
      }

      assert validate(entry) == :ok
    end

    test "invalid id will raise" do
      entry = %ComponentEntry{
        attributes: [%Attr{id: "foo", type: :string}]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "id for attribute \"foo\" must be an atom"
    end

    test "unique attribute ids wont raise" do
      entry = %ComponentEntry{
        attributes: [
          %Attr{id: :foo, type: :string},
          %Attr{id: :bar, type: :integer},
          %Attr{id: :qix, type: :integer}
        ]
      }

      assert validate(entry) == :ok
    end

    test "duplicate attribute ids will raise" do
      entry = %ComponentEntry{
        attributes: [
          %Attr{id: :foo, type: :string},
          %Attr{id: :bar, type: :integer},
          %Attr{id: :foo, type: :integer}
        ]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "duplicate attribute id: :foo"
    end
  end

  describe "attributes types" do
    test "valid attribute types wont raise" do
      entry = %ComponentEntry{
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

      assert validate(entry) == :ok
    end

    test "valid atom types wont raise" do
      entry = entry_with_attr(id: :custom_struct, type: MyModuleStruct)
      assert validate(entry) == :ok
    end

    test "invalid atom types will raise" do
      entry = entry_with_attr(id: :wrong, type: :wrong_type)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type :wrong_type for attr :wrong"
    end

    test "non atom types will raise" do
      entry = entry_with_attr(id: :wrong, type: "wrong_type")
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type \"wrong_type\" for attr :wrong"
    end
  end

  describe "attribute doc" do
    test "nil doc wont raise" do
      entry = entry_with_attr(type: :string, doc: nil)
      assert validate(entry) == :ok
    end

    test "binary doc wont raise" do
      entry = entry_with_attr(type: :string, doc: "some documentation")
      assert validate(entry) == :ok
    end

    test "invalid doc will raise" do
      entry = entry_with_attr(id: :foo, type: :string, doc: 'wrong_doc')
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "doc for attr :foo is not a binary"
    end
  end

  describe "attribute type and default do match" do
    test "with correct defaults, it wont raise" do
      entry = entry_with_attr(type: :integer, default: nil)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :atom, default: :foo)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :string, default: "foo")
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :boolean, default: false)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :integer, default: 12)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :float, default: 12.0)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :list, default: [:foo])
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :any, default: "foo")
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :any, default: 12.0)
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :block, default: "<block/>")
      assert validate(entry) == :ok

      entry = entry_with_attr(type: :slot, default: "<:slot/>")
      assert validate(entry) == :ok

      entry = entry_with_attr(type: MyModuleStruct, default: %MyModuleStruct{})
      assert validate(entry) == :ok
    end

    test "with incorrect defaults, it will raise" do
      entry = entry_with_attr(id: :attr, type: :atom, default: "foo")
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type on default \"foo\" for attr :attr of type :atom"

      entry = entry_with_attr(id: :attr, type: :string, default: :foo)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :string"

      entry = entry_with_attr(id: :attr, type: :integer, default: :foo)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :integer"

      entry = entry_with_attr(id: :attr, type: :float, default: :foo)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :float"

      entry = entry_with_attr(id: :attr, type: :list, default: :foo)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "invalid type on default :foo for attr :attr of type :list"

      entry = entry_with_attr(id: :attr, type: MyModuleStruct, default: :foo)
      e = assert_raise CompileError, fn -> validate(entry) end

      assert e.description =~
               ~r/invalid type on default :foo for attr :attr of type .*MyModuleStruct/
    end
  end

  describe "attribute cannot be required and provide default at the same time" do
    test "with required true and a default, it will raise" do
      entry = entry_with_attr(id: :attr, type: :atom, default: :foo, required: true)
      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "only one of :required or :default must be given for attr :attr"
    end

    test "with required true and no default, it wont raise" do
      entry = entry_with_attr(id: :attr, type: :atom, required: true)
      assert validate(entry) == :ok
    end

    test "with required false and a default, it wont raise" do
      entry = entry_with_attr(id: :attr, type: :atom, default: :foo, required: false)
      assert validate(entry) == :ok
    end
  end

  describe "stories id" do
    test "atom id wont raise" do
      entry = entry_with_story(id: :foo)
      assert validate(entry) == :ok
    end

    test "invalid id will raise" do
      entry = entry_with_story(id: "foo")

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "id for story \"foo\" must be an atom"
    end

    test "unique story ids wont raise" do
      entry = %ComponentEntry{
        stories: [
          %Story{id: :foo},
          %Story{id: :bar},
          %Story{id: :qix}
        ]
      }

      assert validate(entry) == :ok
    end

    test "duplicate story ids will raise" do
      entry = %ComponentEntry{
        stories: [
          %Story{id: :foo},
          %Story{id: :bar},
          %Story{id: :foo}
        ]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "duplicate story id: :foo"
    end

    test "duplicate story ids accross 2 groups wont raise" do
      entry = %ComponentEntry{
        stories: [
          %StoryGroup{id: :group_1, stories: [%Story{id: :foo}]},
          %StoryGroup{id: :group_2, stories: [%Story{id: :foo}]}
        ]
      }

      assert validate(entry) == :ok
    end

    test "duplicate story ids in same group will raise" do
      entry = %ComponentEntry{
        stories: [
          %StoryGroup{id: :group_1, stories: [%Story{id: :foo}, %Story{id: :foo}]},
          %StoryGroup{id: :group_2, stories: [%Story{id: :bar}]}
        ]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "duplicate story id: :foo in group :group_1"
    end
  end

  describe "story attributes match with their definition" do
    test "story attribute without definition wont raise" do
      entry = %ComponentEntry{
        stories: [
          %Story{id: :foo, attributes: %{foo: "bar"}},
          %StoryGroup{id: :group_1, stories: [%Story{id: :foo, attributes: %{foo: "bar"}}]}
        ]
      }

      assert validate(entry) == :ok
    end

    test "story attribute with correct definition wont raise" do
      entry = %ComponentEntry{
        attributes: [
          %Attr{id: :foo, type: :atom},
          %Attr{id: :bar, type: :integer}
        ],
        stories: [
          %Story{id: :foo, attributes: %{foo: :bar}},
          %StoryGroup{id: :group_1, stories: [%Story{id: :foo, attributes: %{bar: 12}}]}
        ]
      }

      assert validate(entry) == :ok
    end

    test "story attribute with invalid definition will raise" do
      entry = %ComponentEntry{
        attributes: [%Attr{id: :bar, type: :atom}],
        stories: [%Story{id: :foo, attributes: %{bar: "bar"}}]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "attribute :bar in story :foo must be of type: :atom"

      entry = %ComponentEntry{
        attributes: [%Attr{id: :bar, type: :atom}],
        stories: [%StoryGroup{id: :group, stories: [%Story{id: :foo, attributes: %{bar: "bar"}}]}]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "attribute :bar in story :foo, group :group must be of type: :atom"
    end
  end

  describe "required story attributes" do
    test "story attribute with all required attributes wont raise" do
      entry = %ComponentEntry{
        attributes: [
          %Attr{id: :foo, type: :atom, required: true},
          %Attr{id: :bar, type: :integer, required: true}
        ],
        stories: [
          %Story{id: :foo, attributes: %{foo: :bar, bar: 12}},
          %StoryGroup{
            id: :group_1,
            stories: [%Story{id: :foo, attributes: %{foo: :bar, bar: 12}}]
          }
        ]
      }

      assert validate(entry) == :ok
    end

    test "story attribute with missing required attributes will raise" do
      entry = %ComponentEntry{
        attributes: [%Attr{id: :bar, type: :atom, required: true}],
        stories: [%Story{id: :foo, attributes: %{}}]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "required attribute :bar missing from story :foo"

      entry = %ComponentEntry{
        attributes: [%Attr{id: :bar, type: :atom, required: true}],
        stories: [%StoryGroup{id: :group, stories: [%Story{id: :foo, attributes: %{}}]}]
      }

      e = assert_raise CompileError, fn -> validate(entry) end
      assert e.description =~ "required attribute :bar missing from story :foo, group :group"
    end
  end

  defp entry_with_attr(opts) do
    %ComponentEntry{
      attributes: [
        %Attr{
          id: opts[:id] || opts[:type],
          type: opts[:type],
          doc: opts[:doc],
          default: opts[:default],
          required: opts[:required]
        }
      ]
    }
  end

  defp entry_with_story(opts) do
    %ComponentEntry{
      stories: [
        %Story{
          id: opts[:id],
          attributes: opts[:attributes] || %{}
        }
      ]
    }
  end

  defp validate(entry), do: EntriesValidator.validate!(entry)
end
