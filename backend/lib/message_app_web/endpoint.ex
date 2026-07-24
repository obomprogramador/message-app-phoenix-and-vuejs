defmodule MessageAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :message_app

  socket "/socket", MessageAppWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  @session_options [
    store: :cookie,
    key: "_message_app_key",
    signing_salt: "TJlDk3k/",
    same_site: "Lax"
  ]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug CORSPlug, origin: "*"
  plug Plug.Session, @session_options
  plug MessageAppWeb.Plugs.SecurityHeaders
  plug MessageAppWeb.Router
end
