defmodule PhxLiveStorybook.Components.Icon do
  @moduledoc false
  use PhxLiveStorybook.Web, :component

  @type icon_provider :: :fa | :hero

  @type t ::
          {icon_provider(), String.t()}
          | {icon_provider(), String.t(), atom}
          | {icon_provider(), String.t(), atom, String.t()}

  @doc """
  FontAwesome icons for internal phx_live_storybook usage.

  ## Examples

      <.fa_icon name="book" class="text-blue-400"/>
      <.fa_icon name="book" style={:duotone} plan={:pro}/>
  """

  attr(:style, :atom,
    default: :solid,
    values: ~w(solid regular light thin duotone brands)a,
    doc: "One of the styles provided by FontAwesome."
  )

  attr(:plan, :atom,
    required: true,
    values: ~w(free pro)a,
    doc: "Free plan will make all icons render with solid style."
  )

  attr(:name, :string, required: true, doc: "The name of the icon, without the fa- prefix.")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:class_list, :list, default: [], doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Any HTML attribute")

  def fa_icon(assigns = %{plan: :free}) do
    ~H(<i class={["fa-solid fa-#{@name}", @class | @class_list]} {@rest}></i>)
  end

  def fa_icon(assigns = %{plan: :pro}) do
    ~H(<i class={["fa-#{@style} fa-#{@name}", @class | @class_list]} {@rest}></i>)
  end

  @doc """
  HeroIcons icons for internal phx_live_storybook usage. Requires :heroicons as a mix dependency.

  ## Examples

      <.hero_icon name="cake" class="w-2 h-2"/>
      <.hero_icon name="cake" style={:mini}/>
  """

  attr(:style, :atom,
    default: :outline,
    values: ~w(outline solid mini)a,
    doc: "One of the styles provided by HeroIcons."
  )

  attr(:name, :string, required: true, doc: "The name of the icon")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:class_list, :list, default: [], doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Any HTML attribute")

  def hero_icon(assigns) do
    if Code.ensure_loaded?(Heroicons) do
      apply(
        Heroicons,
        String.to_atom(assigns[:name]),
        [
          assigns
          |> Map.take([:__changed__, :rest])
          |> Map.put(assigns[:style], true)
          |> update_in([:rest, :class], &[&1, assigns[:class] | assigns[:class_list]])
        ]
      )
    else
      raise """
      Heroicons module is not available.
      Please add :heroicons as a mix dependency.
      """
    end
  end

  @doc """
  Icons defined by storybook users.
  Icon can use different providers: FontAwesome (:fa) and HeroIcons (:hero) are supported.

  ## Examples

      <.user_icon icon={:fa, "book"}/>
      <.user_icon icon={:fa, "book", :thin}/>
      <.user_icon icon={:fa, "book", :duotone, "fa-fw"} class="text-indigo-400"/>
      <.user_icon icon={:hero, "cake"}/>
      <.user_icon icon={:hero, "cake", :mini}/>
      <.user_icon icon={:hero, "cake", :mini, "w-2 h-2"} class="text-indigo-400"/>
  """

  attr(:icon, :any,
    required: true,
    doc: "Icon config, a tuple of 2 to 4 items: {provider, icon, style, classes}",
    examples: [
      {:fa, "book"},
      {:fa, "book", :thin},
      {:fa, "book", :duotone, "fa-fw"},
      {:hero, "cake", :solid, "w-2 h-2"}
    ]
  )

  attr(:fa_plan, :atom,
    required: true,
    values: ~w(free pro)a,
    doc: "Free plan will make all icons render with solid style."
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Any HTML attribute")

  def user_icon(assigns = %{icon: {:fa, name}}) do
    assigns = assign(assigns, name: name)
    ~H(<.fa_icon name={@name} plan={@fa_plan} class={@class} {@rest}/>)
  end

  def user_icon(assigns = %{icon: {:fa, name, style}}) do
    assigns = assign(assigns, name: name, style: style)
    ~H(<.fa_icon name={@name} style={@style} plan={@fa_plan} class={@class} {@rest}/>)
  end

  def user_icon(assigns = %{icon: {:fa, name, style, class}}) do
    assigns = assign(assigns, name: name, style: style, icon_class: class)

    ~H(<.fa_icon name={@name} style={@style} plan={@fa_plan} class_list={[@icon_class, @class]} {@rest}/>)
  end

  def user_icon(assigns = %{icon: {:hero, name}}) do
    assigns = assign(assigns, name: name)
    ~H(<.hero_icon name={@name} class={@class} {@rest}/>)
  end

  def user_icon(assigns = %{icon: {:hero, name, style}}) do
    assigns = assign(assigns, name: name, style: style)
    ~H(<.hero_icon name={@name} style={@style} class={@class} {@rest}/>)
  end

  def user_icon(assigns = %{icon: {:hero, name, style, class}}) do
    assigns = assign(assigns, name: name, style: style, icon_class: class)
    ~H(<.hero_icon name={@name} style={@style} class_list={[@icon_class, @class]} {@rest}/>)
  end
end
