defmodule MessageApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MessageAppWeb.Telemetry,
      MessageApp.Repo,
      {Phoenix.PubSub, name: MessageApp.PubSub},
      MessageAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MessageApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MessageAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
