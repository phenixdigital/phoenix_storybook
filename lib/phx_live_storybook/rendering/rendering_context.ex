defmodule PhxLiveStorybook.Rendering.RenderingContext do
  @moduledoc """
  A struct holding all data needed by `ComponentRenderer` and `CodeRenderer` to render story
  variations.
  """

  alias PhxLiveStorybook.Rendering.{RenderingContext, RenderingVariation}
  alias PhxLiveStorybook.Stories.{Variation, VariationGroup}
  alias PhxLiveStorybook.TemplateHelpers

  @enforce_keys [:id, :dom_id, :type, :story]
  defstruct [
    :id,
    :dom_id,
    :type,
    :function,
    :component,
    :story,
    :variations,
    :template,
    options: []
  ]

  def build(story, variation_or_group, extra_attributes, options \\ [])

  def build(story, variation = %Variation{}, extra_attributes, options) do
    group_id = :single
    id = context_id(story, group_id)
    dom_id = to_dom_id(id)

    %RenderingContext{
      id: id,
      dom_id: dom_id,
      story: story,
      type: story.storybook_type(),
      function: story.function(),
      component: story.component(),
      variations: [
        %RenderingVariation{
          id: variation.id,
          attributes: attributes(variation, dom_id, group_id, extra_attributes),
          slots: variation.slots,
          let: variation.let
        }
      ],
      template: TemplateHelpers.get_template(story.template(), variation.template),
      options: options(story, options)
    }
  end

  def build(story, group = %VariationGroup{variations: variations}, extra_attributes, options) do
    id = context_id(story, group.id)
    dom_id = to_dom_id(id)

    %RenderingContext{
      id: id,
      dom_id: dom_id,
      story: story,
      type: story.storybook_type(),
      function: story.function(),
      component: story.component(),
      variations:
        for variation <- variations do
          %RenderingVariation{
            id: variation.id,
            attributes: attributes(variation, dom_id, group.id, extra_attributes),
            slots: variation.slots,
            let: variation.let
          }
        end,
      template: TemplateHelpers.get_template(story.template(), group.template),
      options: options(story, options)
    }
  end

  defp context_id(story, group_id) do
    story_module_name = story |> to_string() |> String.split(".") |> Enum.at(-1)
    {story_module_name, group_id}
  end

  defp to_dom_id({story_id, group_id}) do
    "#{story_id}-#{group_id}" |> Macro.underscore() |> String.replace("_", "-")
  end

  defp attributes(variation, dom_id, group_id, extra_attributes) do
    extra_attributes = Map.get(extra_attributes, group_id, %{})

    variation.attributes
    |> Map.put(:id, dom_id)
    |> Map.merge(extra_attributes)
  end

  defp options(story, options) do
    Keyword.merge(options, imports: story.imports(), aliases: story.aliases())
  end
end
