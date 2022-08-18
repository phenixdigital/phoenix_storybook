import Config

config :phoenix, :json_library, Jason

config :phx_live_storybook, :env, config_env()
config :phx_live_storybook, :gzip_assets, false

import_config "#{config_env()}.exs"
