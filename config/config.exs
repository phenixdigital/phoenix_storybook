import Config

config :phoenix, :json_library, Jason

config :phoenix_storybook, :env, config_env()
config :phoenix_storybook, :gzip_assets, false

import_config "#{config_env()}.exs"
