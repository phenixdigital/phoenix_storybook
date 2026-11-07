defmodule PhoenixStorybook.Story.ComponentIframeLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias PhoenixStorybook.ExtraAssignsHelpers
  alias PhoenixStorybook.LayoutView
  alias PhoenixStorybook.Rendering.{ComponentRenderer, RenderingContext}
  alias PhoenixStorybook.Stories.{Variation, VariationGroup}
  alias PhoenixStorybook.Story.PlaygroundPreviewLive
  alias PhoenixStorybook.StoryNotFound
  alias PhoenixStorybook.ThemeHelpers
  alias PhoenixStorybook.VariationTitleHelpers

  @playground_topic_salt "phoenix_storybook:playground_topic"
  @playground_token_max_age 86_400

  def mount(_params, _session, socket) do
    {:ok, assign(socket, []), layout: {PhoenixStorybook.LayoutView, :live_iframe}}
  end

  def handle_params(params = %{"story" => story_path}, _uri, socket) do
    case load_story(socket, story_path) do
      {:ok, story} ->
        topic = verified_playground_topic(socket, params["playground_token"])

        if topic do
          PubSub.broadcast!(
            PhoenixStorybook.PubSub,
            topic,
            {:component_iframe_pid, self()}
          )
        end

        ThemeHelpers.call_theme_function(socket.assigns.backend_module, params["theme"])

        {:noreply,
         socket
         |> assign(
           playground: params["playground"],
           story_path: story_path,
           story: story,
           variation_id: params["variation_id"],
           group_id: params["group_id"],
           variation: current_variation(story.storybook_type(), story, params),
           all_variations_mode: all_variations_mode?(params),
           topic: topic,
           theme: params["theme"],
           color_mode: params["color_mode"]
         )
         |> assign_color_mode_class()
         |> assign_extra_assigns()}

      {:error, _error, exception} ->
        raise exception

      {:error, :not_found} ->
        raise StoryNotFound, "unknown story #{inspect(story_path)}"
    end
  end

  # `variations=all` renders every variation (or only `variation_id` when given), stacked.
  defp all_variations_mode?(%{"variations" => "all"}), do: true

  defp all_variations_mode?(%{"variations" => other}),
    do: raise(ArgumentError, "unknown variations param #{inspect(other)}, expected all")

  defp all_variations_mode?(_params), do: false

  defp verified_playground_topic(_socket, nil), do: nil

  defp verified_playground_topic(socket, token) do
    case Phoenix.Token.verify(socket.endpoint, @playground_topic_salt, token,
           max_age: @playground_token_max_age
         ) do
      {:ok, %{"topic" => topic}} when is_binary(topic) -> topic
      _other -> nil
    end
  end

  defp load_story(socket, story_param) do
    story_path = Path.join(story_param)
    socket.assigns.backend_module.load_story(story_path)
  end

  defp assign_color_mode_class(socket = %{assigns: assigns}) do
    class =
      if assigns.backend_module.config(:color_mode) do
        case assigns.color_mode do
          "dark" -> assigns.backend_module.config(:color_mode_sandbox_dark_class, "dark")
          "light" -> assigns.backend_module.config(:color_mode_sandbox_light_class)
          _ -> nil
        end
      end

    assign(socket, :color_mode_class, class)
  end

  defp assign_extra_assigns(socket = %{assigns: %{all_variations_mode: true, story: story}}) do
    assign(
      socket,
      :extra_assigns,
      ExtraAssignsHelpers.init_variation_extra_assigns(story.storybook_type(), story)
    )
  end

  defp assign_extra_assigns(socket) do
    case Map.get(socket.assigns, :variation) do
      nil ->
        assign(socket, :extra_assigns, %{})

      %Variation{id: id} ->
        assign(socket, :extra_assigns, %{{:single, id} => %{}})

      %VariationGroup{id: group_id, variations: variations} ->
        assign(
          socket,
          :extra_assigns,
          for(%Variation{id: id} <- variations, into: %{}, do: {{group_id, id}, %{}})
        )
    end
  end

  def render(assigns) do
    case {assigns.story.storybook_type(), Map.get(assigns, :all_variations_mode, false)} do
      {:example, _} -> render_example(assigns)
      {_, true} -> render_all_variations(assigns)
      _ -> render_component(assigns)
    end
  end

  defp render_component(assigns) do
    assigns =
      assign(
        assigns,
        context:
          RenderingContext.build(
            assigns.backend_module,
            assigns.story,
            assigns.variation,
            variation_extra_attributes(assigns.variation, assigns)
          ),
        iframe_opts:
          assigns.story.container() |> LayoutView.normalize_story_container() |> elem(1)
      )

    ~H"""
    <%= if @variation_id || @group_id do %>
      <%= if @playground do %>
        {live_render(@socket, PlaygroundPreviewLive,
          id: playground_preview_id(@story),
          session: %{
            "story" => @story,
            "variation_id" => @variation_id,
            "theme" => @theme,
            "color_mode" => @color_mode,
            "topic" => @topic,
            "backend_module" => @backend_module
          },
          container: {:div, style: "height: 100vh; width: 100wh;"}
        )}
      <% else %>
        <% {classes, iframe_opts} = Keyword.pop(@iframe_opts, :class) %>
        <div
          {iframe_opts}
          class={[classes, @color_mode_class]}
          {LayoutView.sandbox_attributes(
            @socket,
            {:div, @iframe_opts},
            assigns
          )}
        >
          {ComponentRenderer.render(@context)}
        </div>
      <% end %>
    <% end %>
    """
  end

  # one variation of a group (group_id + variation_id): "Group title › Variation title"
  defp screen_size_section_title(group = %VariationGroup{variations: [grouped_variation]}, %{
         group_id: group_id,
         variation_id: variation_id
       })
       when is_binary(group_id) and is_binary(variation_id) do
    "#{VariationTitleHelpers.variation_title(group)} › #{VariationTitleHelpers.variation_title(grouped_variation)}"
  end

  defp screen_size_section_title(variation_or_group, _assigns),
    do: VariationTitleHelpers.variation_title(variation_or_group)

  # Variations always render as divs here: the screen-size iframe already isolates them.
  defp render_all_variations(assigns) do
    # Most specific wins: a story container with its own class or style keeps it; otherwise the
    # library's existing inline-style default for iframe containers (same layout as the None view's
    # psb: classes, which aren't loaded here).
    {container_classes, container_opts} =
      case assigns.story.container() do
        {_container, opts} when is_list(opts) and opts != [] -> Keyword.pop(opts, :class)
        _default_container -> {nil, elem(LayoutView.normalize_story_container(:iframe), 1)}
      end

    # group_id / variation_id select one entry (current_variation/3 resolves and validates them)
    rendered_variations =
      if assigns.variation_id || assigns.group_id,
        do: [assigns.variation],
        else: assigns.story.variations()

    assigns =
      assign(assigns,
        rendered_variations: rendered_variations,
        container_classes: container_classes,
        container_opts: container_opts
      )

    ~H"""
    <section
      :for={variation <- @rendered_variations}
      id={"psb-screen-size-variation-#{variation.id}"}
      style="padding: 8px; border-bottom: 1px dashed rgba(128, 128, 128, 0.35);"
    >
      <%!-- ponytail: paddings, not margins, so nothing collapses out of body and the measured height is exact.
           8px section + the container's 5px = the None view's card (p-2) + default container --%>
      <h3 style="margin: 0; padding: 4px 5px; font: 600 12px/1.4 system-ui, sans-serif; opacity: 0.6;">
        {screen_size_section_title(variation, assigns)}
      </h3>
      <div
        {@container_opts}
        class={[@container_classes, @color_mode_class]}
        {LayoutView.sandbox_attributes(@socket, {:div, @container_opts}, assigns)}
      >
        {ComponentRenderer.render(
          RenderingContext.build(
            @backend_module,
            @story,
            variation,
            variation_extra_attributes(variation, assigns)
          )
        )}
      </div>
    </section>
    """
  end

  defp render_example(assigns) do
    theme = Map.get(assigns, :theme)
    {_container, container_opts} = LayoutView.normalize_story_container(assigns.story.container())
    {id, container_opts} = Keyword.pop(container_opts, :id)

    assigns =
      assigns
      |> assign(:example_live_id, id || "example-#{story_id(assigns.story)}-#{theme}")
      |> assign(:example_container, {:div, example_container_opts(assigns, container_opts)})

    ~H"""
    {live_render(@socket, @story,
      id: @example_live_id,
      session: %{"theme" => @theme},
      container: @example_container
    )}
    """
  end

  defp example_container_opts(assigns, container_opts) do
    {classes, container_opts} = Keyword.pop(container_opts, :class)
    Keyword.put(container_opts, :class, [classes, assigns[:color_mode_class]])
  end

  defp playground_preview_id(story) do
    module = story |> Macro.underscore() |> String.replace("/", "_")
    "#{module}-playground-preview"
  end

  defp story_id(story) do
    story |> Macro.underscore() |> String.replace("/", "_")
  end

  defp current_variation(_type, story, %{"playground" => _, "group_id" => group_id}) do
    raise StoryNotFound,
          "group_id is not supported with playground (group_id #{inspect(group_id)} in story #{inspect(story)})"
  end

  defp current_variation(type, story, params = %{"group_id" => group_id})
       when type in [:component, :live_component] do
    group = find_variation_group(story, group_id)

    case params do
      %{"variation_id" => variation_id} ->
        %VariationGroup{group | variations: [find_variation_in_group(story, group, variation_id)]}

      _ ->
        group
    end
  end

  defp current_variation(type, story, %{"variation_id" => variation_id})
       when type in [:component, :live_component] do
    Enum.find(story.variations(), &(to_string(&1.id) == variation_id)) ||
      raise StoryNotFound, "unknown variation #{inspect(variation_id)} in story #{inspect(story)}"
  end

  defp current_variation(type, story, _) when type in [:component, :live_component] do
    case story.variations() do
      [variation | _] -> variation
      _ -> nil
    end
  end

  defp current_variation(:example, _story, _params), do: nil

  defp current_variation(type, story, _params) do
    raise StoryNotFound,
          "story #{inspect(story)} of type #{inspect(type)} can't be rendered in an iframe"
  end

  defp find_variation_group(story, group_id) do
    case Enum.find(story.variations(), &(to_string(&1.id) == group_id)) do
      group = %VariationGroup{} ->
        group

      %Variation{} ->
        raise StoryNotFound,
              "#{inspect(group_id)} is a variation, not a variation group, in story #{inspect(story)}"

      nil ->
        raise StoryNotFound,
              "unknown variation group #{inspect(group_id)} in story #{inspect(story)}"
    end
  end

  defp find_variation_in_group(story, group, variation_id) do
    Enum.find(group.variations, &(to_string(&1.id) == variation_id)) ||
      raise StoryNotFound,
            "unknown variation #{inspect(variation_id)} in group #{inspect(to_string(group.id))} of story #{inspect(story)}"
  end

  defp variation_extra_attributes(%Variation{id: variation_id}, assigns) do
    extra_assigns = Map.get(assigns.extra_assigns, {:single, variation_id}, %{})

    extra_assigns =
      case ThemeHelpers.theme_assign(assigns.backend_module, assigns.theme) do
        {assign_key, theme} -> Map.put(extra_assigns, assign_key, theme)
        nil -> extra_assigns
      end

    %{variation_id => extra_assigns}
  end

  defp variation_extra_attributes(%VariationGroup{id: group_id}, assigns) do
    maybe_theme_assign = ThemeHelpers.theme_assign(assigns.backend_module, assigns.theme)

    for {{^group_id, variation_id}, extra_assigns} <- assigns.extra_assigns,
        into: %{} do
      case maybe_theme_assign do
        {assign_key, theme} -> {variation_id, Map.put(extra_assigns, assign_key, theme)}
        _ -> {variation_id, extra_assigns}
      end
    end
  end

  def handle_event("psb-assign", assign_params, socket = %{assigns: assigns}) do
    {variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_set_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply,
     assign(socket, extra_assigns: Map.put(assigns.extra_assigns, variation_id, extra_assigns))}
  end

  def handle_event("psb-toggle", assign_params, socket = %{assigns: assigns}) do
    {variation_id, extra_assigns} =
      ExtraAssignsHelpers.handle_toggle_variation_assign(
        assign_params,
        assigns.extra_assigns,
        assigns.story
      )

    {:noreply,
     assign(socket, extra_assigns: Map.put(assigns.extra_assigns, variation_id, extra_assigns))}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  def handle_info(message, socket) do
    story = socket.assigns[:story]

    if is_atom(story) and function_exported?(story, :handle_info, 2) do
      story.handle_info(message, socket)
    else
      {:noreply, socket}
    end
  end
end
