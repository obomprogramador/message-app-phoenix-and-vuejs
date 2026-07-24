import Config

config :message_app, MessageAppWeb.Endpoint,
  url: [host: "example.com"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :swoosh, :api_client, Swoosh.ApiClient.Finch

config :logger, level: :info
