import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sync_app, SyncAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qoUgJXWui1UCaOhz4hEV1EbECSUU85HT7eA7TAgHKPc88A9qj2hJP5CzPLpvfFo/",
  server: false

# In test we don't send emails
config :sync_app, SyncApp.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
