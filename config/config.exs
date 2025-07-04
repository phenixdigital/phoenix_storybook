import Config

config :phoenix, :json_library, Jason

config :phoenix_storybook, :env, config_env()
config :elixir, :dbg_callback, {PhoenixStorybook.Dbg, :debug_fun, [:stdio]}

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [module: Earmark.Parser.LineScanner]
  ]

import_config "#{config_env()}.exs"
