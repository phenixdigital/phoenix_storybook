defmodule PhxLiveStorybook.Application do
  @moduledoc false

  use Application
  alias PhxLiveStorybook.Events.Instrumenter

  @impl true
  def start(_type, _args) do
    Instrumenter.setup()

    Supervisor.start_link(
      [
        {Phoenix.PubSub, name: PhxLiveStorybook.PubSub},
        {PhxLiveStorybook.ExsCompiler, []}
      ],
      strategy: :one_for_one,
      name: PhxLiveStorybook.Supervisor
    )
  end
end
