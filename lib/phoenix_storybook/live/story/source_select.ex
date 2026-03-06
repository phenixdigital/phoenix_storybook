defmodule PhoenixStorybook.Story.SourceSelect do
  @moduledoc false
  use PhoenixStorybook.Web, :component

  attr :form_id, :string, required: true
  attr :as, :atom, required: true
  attr :field, :atom, required: true
  attr :label, :string, default: nil
  attr :options, :list, required: true
  attr :value, :any, default: nil
  attr :change_event, :string, required: true
  attr :change_target, :any, default: nil

  attr :class, :string,
    default:
      "psb psb:flex psb:flex-col psb:md:flex-row psb:space-y-1 psb:md:space-x-2 psb:justify-end psb:w-full psb:mb-6"

  attr :label_class, :string,
    default:
      "psb psb:text-gray-400 psb:dark:text-slate-300 psb:text-xs psb:md:text-sm psb:self-end psb:md:self-center"

  attr :select_class, :string, default: nil

  def source_file_select(assigns) do
    ~H"""
    <.form :let={f} for={%{}} as={@as} id={@form_id} class={@class}>
      {if @label, do: label(f, @field, @label, class: @label_class)}
      {select(f, @field, @options, select_options(assigns))}
    </.form>
    """
  end

  @default_select_class "psb psb:cursor-pointer psb:form-select psb:dark:bg-slate-800 psb:text-gray-600 psb:dark:text-slate-300 psb:pr-10 psb:py-1 psb:border-gray-300 psb:dark:border-slate-600 psb:focus:outline-none psb:focus:ring-indigo-600 psb:dark:focus:ring-sky-400 psb:focus:border-indigo-600 psb:dark:focus:border-sky-400 psb:text-xs psb:md:text-sm psb:rounded-md"

  defp select_options(assigns = %{change_target: nil}) do
    [
      "phx-change": assigns.change_event,
      class: [@default_select_class, assigns.select_class],
      value: assigns.value
    ]
  end

  defp select_options(assigns) do
    [
      "phx-change": assigns.change_event,
      "phx-target": assigns.change_target,
      class: [@default_select_class, assigns.select_class],
      value: assigns.value
    ]
  end
end
