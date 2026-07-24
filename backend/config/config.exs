import Config

config :message_app,
  ecto_repos: [MessageApp.Repo],
  generators: [timestamp_type: :utc_datetime]

config :message_app, MessageAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: MessageAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MessageApp.PubSub,
  live_view: [signing_salt: "hMfkpQvS"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
