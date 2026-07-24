import Config

config :message_app, MessageAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-only-secret-key-base-that-is-long-enough-for-phoenix-to-accept",
  server: false

config :message_app, MessageApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("PGHOST") || "localhost",
  database: "message_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :message_app, :generators,
  primary_key_type: :binary_id,
  foreign_key_type: :binary_id

config :logger, level: :warning
