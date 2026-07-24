defmodule MessageAppWeb.MessageController do
  use MessageAppWeb, :controller

  alias MessageApp.Messages

  action_fallback MessageAppWeb.FallbackController

  def index(conn, %{"contact_id" => contact_id} = params) do
    messages = Messages.list_messages(contact_id, params)
    render(conn, :index, messages: messages)
  end

  def create(conn, %{"contact_id" => contact_id, "message" => message_params} = params) do
    attrs =
      message_params
      |> Map.put("contact_id", contact_id)
      |> Map.put("from_contact_id", params["from_contact_id"])

    with {:ok, message} <- Messages.send_message(attrs) do
      Phoenix.PubSub.broadcast(
        MessageApp.PubSub,
        "messages:#{contact_id}",
        {:new_message, %{
          id: message.id,
          content: message.content,
          direction: message.direction,
          is_read: message.is_read,
          contact_id: message.contact_id,
          from_contact_id: message.from_contact_id,
          inserted_at: message.inserted_at,
          updated_at: message.updated_at
        }}
      )

      conn
      |> put_status(:created)
      |> render(:show, message: message)
    end
  end

  def search(conn, %{"contact_id" => contact_id, "q" => query} = params) do
    messages = Messages.search_messages(contact_id, query, params)
    render(conn, :index, messages: messages)
  end

  def mark_as_read(conn, %{"id" => id}) do
    with {:ok, message} <- Messages.mark_as_read(id) do
      render(conn, :show, message: message)
    end
  end
end
