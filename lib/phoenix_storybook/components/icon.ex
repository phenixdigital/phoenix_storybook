defmodule PhoenixStorybook.Components.Icon do
  @moduledoc false
  use PhoenixStorybook.Web, :component

  @type icon_provider :: :fa | :hero | :local

  @type t ::
          {icon_provider(), String.t()}
          | {icon_provider(), String.t(), atom}
          | {icon_provider(), String.t(), atom, String.t()}

  @doc """
  FontAwesome icons for internal phoenix_storybook usage.

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
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:class_list, :list, default: [], doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Any HTML attribute")

  def fa_icon(assigns = %{plan: :free}) do
    ~H(<i class={["fa-solid fa-#{@name}", @class | @class_list]} {@rest}></i>)
  end

  def fa_icon(assigns = %{plan: :pro}) do
    ~H(<i class={["fa-#{@style} fa-#{@name}", @class | @class_list]} {@rest}></i>)
  end

  @doc """
  HeroIcons icons for internal phoenix_storybook usage. Requires :heroicons as a mix dependency.

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
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
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
  Local icons for internal phoenix_storybook usage.

  ## Examples

      <.local_icon name="hero-cake" />
      <.local_icon name="hero-cake" class="text-blue-400"/>

  """

  attr :class, :any, default: nil, doc: "Additional CSS classes"
  attr :name, :string, required: true, doc: "The name of the icon, without the fa- prefix."
  attr :rest, :global, doc: "Any HTML attribute"

  def local_icon(assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
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
      <.user_icon icon={:local, "hero-cake"}/>
      <.user_icon icon={:local, "hero-cake", nil, "w-2 h-2"} class="text-indigo-400"/>
  """

  attr :class, :string, default: nil, doc: "Additional CSS classes"

  attr :fa_plan, :atom,
    doc: "Free plan will make all icons render with solid style.",
    required: true,
    values: ~w(free pro)a

  attr :icon, :any,
    doc: "Icon config, a tuple of 2 to 4 items: {provider, icon, style, classes}",
    examples: [
      {:fa, "book"},
      {:fa, "book", :thin},
      {:fa, "book", :duotone, "fa-fw"},
      {:hero, "cake", :solid, "w-2 h-2"},
      {:local, "hero-cake"},
      {:local, "hero-cake", nil, "w-2 h-2"}
    ],
    required: true

  attr :rest, :global, doc: "Any HTML attribute"

  def user_icon(assigns = %{class: class, icon: icon}) do
    provider = safe_elem(icon, 0)

    assigns =
      assign(assigns,
        class: [safe_elem(icon, 3), class],
        name: safe_elem(icon, 1),
        provider: provider,
        style: safe_elem(icon, 2)
      )

    case provider do
      :fa -> ~H(<.fa_icon class={@class} name={@name} plan={@fa_plan} style={@style} {@rest} />)
      :hero -> ~H(<.hero_icon class={@class} name={@name} style={@style} {@rest} />)
      :local -> ~H(<.local_icon class={@class} name={@name} {@rest} />)
    end
  end

  defp safe_elem(tuple, idx), do: if(idx < tuple_size(tuple), do: elem(tuple, idx), else: nil)
end
