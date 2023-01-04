defmodule PhxLiveStorybook.Icon do
  @moduledoc """
  Definitions of icon and valid icon providers to be used in specs and behaviours.
  """
  @type icon_provider :: :fa | :hero

  @type t ::
          {icon_provider(), String.t()}
          | {icon_provider(), String.t(), atom}
          | {icon_provider(), String.t(), atom, String.t()}
end
