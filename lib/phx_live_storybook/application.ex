defmodule PhxLiveStorybook.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([{Phoenix.PubSub, name: PhxLiveStorybook.PubSub}],
      strategy: :one_for_one,
      name: PhxLiveStorybook.Supervisor
    )
  end
end
