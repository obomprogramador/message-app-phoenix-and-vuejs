import Config

config :message_app, MessageAppWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE", "dev-only-secret-key-base-that-is-long-enough-for-phoenix-to-accept"),
  watchers: []

config :message_app, MessageApp.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "postgres"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database: System.get_env("PGDATABASE", "message_app_dev"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :message_app, :generators,
  primary_key_type: :binary_id,
  foreign_key_type: :binary_id

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20

config :message_app, :dev_routes, true
