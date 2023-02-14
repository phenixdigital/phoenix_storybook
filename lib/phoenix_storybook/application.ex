defmodule PhoenixStorybook.Application do
  @moduledoc false

  use Application
  alias PhoenixStorybook.Events.Instrumenter

  @impl true
  def start(_type, _args) do
    Instrumenter.setup()

    Supervisor.start_link(
      [
        {Phoenix.PubSub, name: PhoenixStorybook.PubSub},
        {PhoenixStorybook.ExsCompiler, []}
      ],
      strategy: :one_for_one,
      name: PhoenixStorybook.Supervisor
    )
  end
end
