defmodule PhxLiveStorybook.Events.EventLog do
  @moduledoc """
  Data structure for event logs displayed in each story's playground
  """
  @type t :: %__MODULE__{
          type: :live_view | :component,
          parent_pid: pid(),
          view: atom(),
          event: binary(),
          params: map(),
          assigns: map(),
          time: Time.t()
        }

  defstruct [:type, :parent_pid, :view, :event, :params, :assigns, :time]
end
