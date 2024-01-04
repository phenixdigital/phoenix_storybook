defmodule PhoenixStorybook.Web do
  @moduledoc false

  @doc false
  def controller do
    quote do
      @moduledoc false

      use Phoenix.Controller, namespace: PhoenixStorybook
      import Plug.Conn
      unquote(view_helpers())
    end
  end

  @doc false
  def view do
    quote do
      @moduledoc false

      use Phoenix.View,
        namespace: PhoenixStorybook,
        root: "lib/phoenix_storybook/templates"

      import PhoenixStorybook.Components.Icon

      unquote(view_helpers())
    end
  end

  @doc false
  def live_view do
    quote do
      @moduledoc false
      use Phoenix.LiveView,
        layout: {PhoenixStorybook.LayoutView, :live}

      import PhoenixStorybook.Components.Icon

      unquote(view_helpers())
    end
  end

  @doc false
  def component do
    quote do
      @moduledoc false
      use Phoenix.Component
      unquote(view_helpers())
    end
  end

  @doc false
  def live_component do
    quote do
      @moduledoc false
      use Phoenix.LiveComponent
      import PhoenixStorybook.Components.Icon
      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import convenience functions for LiveView rendering
      import Phoenix.Component

      alias PhoenixStorybook.Router.Helpers, as: Routes
    end
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
