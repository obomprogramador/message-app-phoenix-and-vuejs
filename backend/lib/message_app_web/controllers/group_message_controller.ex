defmodule MessageAppWeb.GroupMessageController do
  use MessageAppWeb, :controller

  alias MessageApp.Groups

  action_fallback MessageAppWeb.FallbackController

  def index(conn, %{"group_id" => group_id} = params) do
    messages = Groups.list_group_messages(group_id, params)
    render(conn, :index, messages: messages)
  end

  def create(conn, %{"group_id" => group_id, "message" => %{"sender_id" => sender_id} = message_params}) do
    with {:ok, message} <- Groups.send_group_message(group_id, sender_id, Map.put(message_params, "group_id", group_id)) do
      message = MessageApp.Repo.preload(message, :sender)

      Phoenix.PubSub.broadcast(
        MessageApp.PubSub,
        "group:#{group_id}",
        {:new_message, %{
          id: message.id,
          content: message.content,
          is_read: message.is_read,
          group_id: message.group_id,
          sender_id: message.sender_id,
          sender: %{
            id: message.sender.id,
            name: message.sender.name,
            nickname: message.sender.nickname,
            avatar_url: message.sender.avatar_url
          },
          inserted_at: message.inserted_at,
          updated_at: message.updated_at
        }}
      )

      conn
      |> put_status(:created)
      |> render(:show, message: message)
    end
  end
end
