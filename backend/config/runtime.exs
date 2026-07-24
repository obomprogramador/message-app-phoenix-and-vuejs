import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :remote_ip]

config :logger, level: System.get_env("LOG_LEVEL", "info") |> String.to_atom()

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :message_app, MessageApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :message_app, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :message_app, MessageAppWeb.Endpoint,
    server: System.get_env("PHX_SERVER", "false") == "true",
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    check_origin:
      System.get_env("PHX_ALLOWED_ORIGINS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> case do
        [] -> false
        origins -> origins
      end
end
