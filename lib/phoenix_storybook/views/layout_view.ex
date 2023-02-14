defmodule PhoenixStorybook.LayoutView do
  @moduledoc false
  use PhoenixStorybook.Web, :view

  alias Makeup.Styles.HTML.StyleMap
  alias Phoenix.LiveView.JS
  alias PhoenixStorybook.AssetHelpers
  alias PhoenixStorybook.{FolderEntry, StoryEntry}
  alias PhoenixStorybook.ThemeHelpers

  def render_breadcrumb(socket, story_path, opts \\ []) do
    assigns = %{
      breadcrumbs: breadcrumb(socket, story_path),
      fa_plan: backend_module(socket).config(:font_awesome_plan, :free),
      span_class: opts[:span_class]
    }

    ~H"""
    <.intersperse :let={item} enum={@breadcrumbs}>
      <:separator>
        <.fa_icon
          style={:thin}
          name="angle-right"
          class="lsb-px-2 lsb-text-slate-500"
          plan={@fa_plan}
        />
      </:separator>
      <span class={[
        "lsb",
        @span_class,
        "[&:not(:last-child)]:lsb-truncate last:lsb-whitespace-nowrap"
      ]}>
        <%= item %>
      </span>
    </.intersperse>
    """
  end

  defp makeup_stylesheet(conn) do
    style = storybook_setting(conn, :makeup_style, :monokai_style)
    apply(StyleMap, style, []) |> Makeup.stylesheet()
  end

  defp live_socket_path(conn = %Plug.Conn{}) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  defp storybook_css_path(conn), do: storybook_setting(conn, :css_path)
  defp storybook_js_path(conn), do: storybook_setting(conn, :js_path)

  defp title(conn_or_socket), do: storybook_setting(conn_or_socket, :title, "Live Storybook")

  defp title_prefix(conn_or_socket) do
    title(conn_or_socket) <> " - "
  end

  defp fa_kit_id(conn_or_socket) do
    storybook_setting(conn_or_socket, :font_awesome_kit_id)
  end

  defp wait_for_icons?(conn_or_socket) do
    if fa_kit_id(conn_or_socket), do: "lsb-wait-for-icons", else: nil
  end

  defp storybook_setting(conn_or_socket, key, default \\ nil)

  defp storybook_setting(conn_or_socket, key, default) do
    backend_module = backend_module(conn_or_socket)
    backend_module.config(key, default)
  end

  defp backend_module(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.backend_module
  defp backend_module(conn = %Plug.Conn{}), do: conn.private.backend_module

  defp assets_path(s = %Phoenix.LiveView.Socket{}), do: s.assigns.__assigns__.assets_path
  defp assets_path(conn = %Plug.Conn{}), do: conn.private.assets_path

  defp application_static_path(path), do: Path.join("/", path)

  defp asset_path(conn_or_socket, path) do
    assets_path = assets_path(conn_or_socket)
    Path.join(assets_path, asset_file_name(path))
  end

  @manifest_path Path.expand("static/cache_manifest.json", :code.priv_dir(:phoenix_storybook))
  @external_resource @manifest_path

  if Application.compile_env(:phoenix_storybook, :env) == :prod do
    @manifest AssetHelpers.parse_manifest(@manifest_path)

    defp asset_file_name(asset) do
      if String.ends_with?(asset, [".js", ".css"]) do
        @manifest |> AssetHelpers.asset_file_name(asset, :prod)
      else
        asset
      end
    end
  else
    defp asset_file_name(path), do: path
  end

  defp breadcrumb(socket, story_path) do
    backend_module = backend_module(socket)

    {_, breadcrumb} =
      for path_item <- Path.split(story_path), reduce: {"", []} do
        {path, breadcrumb} ->
          path = Path.join(["/", path, path_item])

          case backend_module.find_entry_by_path(path) do
            %FolderEntry{name: name} -> {path, [name | breadcrumb]}
            %StoryEntry{name: name} -> {path, [name | breadcrumb]}
            nil -> {path, breadcrumb}
          end
      end

    Enum.reverse(breadcrumb)
  end

  defp themes(socket) do
    backend_module = backend_module(socket)
    backend_module.config(:themes, nil)
  end

  defp current_theme_dropdown_class(socket, assigns) do
    themes = themes(socket)
    current_theme = Map.get(assigns, :theme)

    case Enum.find(themes, fn {theme, _} -> theme == current_theme end) do
      nil -> ""
      {_, opts} -> Keyword.get(opts, :dropdown_class)
    end
  end

  defp show_dropdown_transition do
    {"lsb-ease-out lsb-duration-200", "lsb-opacity-0 lsb-scale-95",
     "lsb-opacity-100 lsb-scale-100"}
  end

  defp hide_dropdown_transition do
    {"lsb-ease-out lsb-duration-200", "lsb-opacity-100 lsb-scale-100",
     "lsb-opacity-0 lsb-scale-95"}
  end

  def sandbox_class(conn_or_socket, container, %{theme: nil}) do
    main_sandbox_class(conn_or_socket, container)
  end

  def sandbox_class(conn_or_socket, container, %{theme: theme}) do
    backend_module = backend_module(conn_or_socket)

    [
      ThemeHelpers.theme_sandbox_class(backend_module, theme)
      | main_sandbox_class(conn_or_socket, container)
    ]
  end

  defp main_sandbox_class(conn_or_socket, container) do
    container_class =
      case container do
        {_tag, opts} -> Keyword.get(opts, :class)
        _ -> nil
      end

    ["lsb-sandbox", container_class, backend_module(conn_or_socket).config(:sandbox_class)]
  end
end
