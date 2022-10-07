defmodule PhxLiveStorybook.Rendering.RenderingContext do
  @moduledoc """
  A struct holding all data needed by `ComponentRenderer` and `CodeRenderer` to render story
  variations.
  """

  alias PhxLiveStorybook.Rendering.{RenderingContext, RenderingVariation}
  alias PhxLiveStorybook.Stories.{Variation, VariationGroup}
  alias PhxLiveStorybook.TemplateHelpers

  @enforce_keys [:group_id, :dom_id, :type, :story]
  defstruct [
    :group_id,
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
    dom_id = dom_id(story, group_id)

    %RenderingContext{
      group_id: group_id,
      dom_id: dom_id,
      story: story,
      type: story.storybook_type(),
      function: function(story.storybook_type(), story),
      component: component(story.storybook_type(), story),
      variations: [
        %RenderingVariation{
          id: variation.id,
          dom_id: variation_dom_id(dom_id, variation.id),
          attributes: attributes(variation, group_id, dom_id, extra_attributes),
          slots: variation.slots,
          let: variation.let
        }
      ],
      template: TemplateHelpers.get_template(story.template(), variation.template),
      options: options(story, options)
    }
  end

  def build(story, group = %VariationGroup{variations: variations}, extra_attributes, options) do
    dom_id = dom_id(story, group.id)

    %RenderingContext{
      group_id: group.id,
      dom_id: dom_id,
      story: story,
      type: story.storybook_type(),
      function: function(story.storybook_type(), story),
      component: component(story.storybook_type(), story),
      variations:
        for variation <- variations do
          %RenderingVariation{
            id: variation.id,
            dom_id: variation_dom_id(dom_id, variation.id),
            attributes: attributes(variation, group.id, dom_id, extra_attributes),
            slots: variation.slots,
            let: variation.let
          }
        end,
      template: TemplateHelpers.get_template(story.template(), group.template),
      options: options(story, options)
    }
  end

  defp component(:component, _story), do: nil
  defp component(:live_component, story), do: story.component()

  defp function(:component, story), do: story.function()
  defp function(:live_component, _story), do: nil

  defp dom_id(story, group_id) do
    story_module_name = story |> to_string() |> String.split(".") |> Enum.at(-1)
    "#{story_module_name}-#{group_id}" |> Macro.underscore() |> String.replace("_", "-")
  end

  defp variation_dom_id(dom_id, variation_id) do
    "#{dom_id}-#{variation_id}" |> Macro.underscore() |> String.replace("_", "-")
  end

  defp attributes(variation, group_id, dom_id, extra_attributes) do
    extra_attributes =
      Map.get_lazy(extra_attributes, variation.id, fn ->
        Map.get(extra_attributes, {group_id, variation.id}, %{})
      end)

    variation.attributes
    |> Map.put(:id, variation_dom_id(dom_id, variation.id))
    |> Map.merge(extra_attributes)
  end

  defp options(story, options) do
    Keyword.merge(options, imports: story.imports(), aliases: story.aliases())
  end
end
