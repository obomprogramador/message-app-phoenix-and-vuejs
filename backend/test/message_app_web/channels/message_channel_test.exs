defmodule MessageAppWeb.MessageChannelTest do
  use MessageAppWeb.ChannelCase

  alias MessageAppWeb.UserSocket

  setup do
    contact = insert(:contact)
    %{contact: contact}
  end

  describe "join messages:contact_id" do
    test "permite join com contact_id correto", %{contact: contact} do
      {:ok, _, _socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("messages:#{contact.id}")
    end

    test "rejeita join com contact_id diferente", %{contact: contact} do
      other_contact = insert(:contact)

      assert {:error, %{reason: "unauthorized"}} =
               socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
               |> subscribe_and_join("messages:#{other_contact.id}")
    end
  end

  describe "handle_in new_message" do
    test "envia mensagem e retorna ok", %{contact: contact} do
      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("messages:#{contact.id}")

      ref = push(socket, "new_message", %{"content" => "Ola", "direction" => "sent"})

      assert_reply ref, :ok, %{id: _id}
    end

    test "retorna erro para conteudo vazio", %{contact: contact} do
      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("messages:#{contact.id}")

      ref = push(socket, "new_message", %{"content" => "", "direction" => "sent"})

      assert_reply ref, :error, %{errors: _}
    end
  end

  describe "handle_in mark_as_read" do
    test "marca mensagens como lidas e faz broadcast", %{contact: contact} do
      message = insert(:message, contact: contact, is_read: false)

      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("messages:#{contact.id}")

      ref = push(socket, "mark_as_read", %{"message_ids" => [message.id]})

      assert_reply ref, :ok, %{}

      updated_message = MessageApp.Repo.get!(MessageApp.Messages.Message, message.id)
      assert updated_message.is_read == true
    end
  end

  describe "handle_info new_message (PubSub)" do
    test "encaminha mensagem do PubSub para o cliente", %{contact: contact} do
      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("messages:#{contact.id}")

      payload = %{
        id: Ecto.UUID.generate(),
        content: "Msg do PubSub",
        direction: "received",
        is_read: false,
        contact_id: contact.id,
        from_contact_id: contact.id,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      send(socket.channel_pid, {:new_message, payload})

      assert_push "new_message", ^payload
    end
  end
end
