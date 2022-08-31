defmodule PhxLiveStorybook.Instrumenter do
  @moduledoc false
  alias Phoenix.PubSub

  def setup do
    events = [
      [:phoenix, :live_view, :handle_event, :stop],
      [:phoenix, :live_component, :handle_event, :stop]
    ]

    :telemetry.attach_many("lsb-instrumenter", events, &handle_event/4, nil)
  end

  def handle_event([:phoenix, :live_view, :handle_event, :stop], measurements, metadata, _config) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "event_logs",
      {:live_view_event, measurements, metadata}
    )
  end

  def handle_event(
        [:phoenix, :live_component, :handle_event, :stop],
        measurements,
        metadata,
        _config
      ) do
    PubSub.broadcast!(
      PhxLiveStorybook.PubSub,
      "event_logs",
      {:live_component_event, measurements, metadata}
    )
  end
end
