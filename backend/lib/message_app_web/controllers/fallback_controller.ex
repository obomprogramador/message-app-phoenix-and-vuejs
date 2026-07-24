defmodule MessageAppWeb.FallbackController do
  use MessageAppWeb, :controller

  alias MessageAppWeb.ChangesetJSON

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MessageAppWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :already_linked}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MessageAppWeb.ErrorJSON)
    |> render(:"422")
  end
end
