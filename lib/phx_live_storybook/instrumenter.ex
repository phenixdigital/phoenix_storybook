defmodule PhxLiveStorybook.Instrumenter do
  @moduledoc """
  Event handlers for LiveView exposed telemetry events
  """
  alias Phoenix.PubSub
  alias PhxLiveStorybook.EventLog

  def setup do
    events = [
      [:phoenix, :live_view, :handle_event, :stop],
      [:phoenix, :live_component, :handle_event, :stop]
    ]

    :telemetry.attach_many("lsb-instrumenter", events, &__MODULE__.handle_event/4, nil)
  end

  def handle_event([:phoenix, :live_view, :handle_event, :stop], _measurements, metadata, _config) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "event_logs:#{inspect(metadata.socket.root_pid)}",
      %{metadata_to_event_log(metadata) | type: :live_view}
    )
  end

  def handle_event(
        [:phoenix, :live_component, :handle_event, :stop],
        _measurements,
        metadata,
        _config
      ) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "event_logs:#{inspect(metadata.socket.root_pid)}",
      %{metadata_to_event_log(metadata) | type: :component}
    )
  end

  defp metadata_to_event_log(metadata) do
    %EventLog{
      parent_pid: metadata.socket.parent_pid,
      view: metadata.socket.view,
      event: metadata.event,
      params: metadata.params,
      assigns: metadata.socket.assigns
    }
  end
end
