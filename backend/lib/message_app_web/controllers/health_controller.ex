defmodule MessageAppWeb.HealthController do
  use MessageAppWeb, :controller

  def index(conn, _params) do
    db_ok? =
      case Ecto.Adapters.SQL.query(MessageApp.Repo, "SELECT 1", [], timeout: 2_000) do
        {:ok, _} -> true
        _ -> false
      end

    status_code = if db_ok?, do: 200, else: 503
    status_text = if(db_ok?, do: "ok", else: "degraded")
    db_text = if(db_ok?, do: "connected", else: "disconnected")

    conn
    |> put_status(status_code)
    |> json(%{status: status_text, db: db_text})
  end
end
