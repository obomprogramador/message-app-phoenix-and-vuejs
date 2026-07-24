defmodule MessageAppWeb.GroupChannelTest do
  use MessageAppWeb.ChannelCase

  alias MessageAppWeb.UserSocket

  setup do
    contact = insert(:contact)
    group = insert(:group, created_by: contact)
    insert(:group_member, group: group, contact: contact, role: "member")

    %{contact: contact, group: group}
  end

  describe "join group:group_id" do
    test "permite join para membro do grupo", %{contact: contact, group: group} do
      {:ok, _, _socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("group:#{group.id}")
    end

    test "rejeita join para nao-membro", %{group: group} do
      other_contact = insert(:contact)

      assert {:error, %{reason: "unauthorized"}} =
               socket(UserSocket, "user_socket:#{other_contact.id}", %{contact_id: other_contact.id})
               |> subscribe_and_join("group:#{group.id}")
    end

    test "rejeita join para grupo inexistente", %{contact: contact} do
      fake_id = Ecto.UUID.generate()

      assert {:error, %{reason: "group not found"}} =
               socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
               |> subscribe_and_join("group:#{fake_id}")
    end
  end

  describe "handle_in new_message" do
    test "envia mensagem no grupo", %{contact: contact, group: group} do
      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket, "new_message", %{"content" => "Ola grupo!"})

      assert_reply ref, :ok, %{id: _id}
    end

    test "retorna erro para conteudo vazio", %{contact: contact, group: group} do
      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket, "new_message", %{"content" => ""})

      assert_reply ref, :error, %{errors: _}
    end
  end

  describe "handle_in mark_as_read" do
    test "marca mensagens do grupo como lidas", %{contact: contact, group: group} do
      message = insert(:group_message, group: group, sender: contact, is_read: false)

      {:ok, _, socket} =
        socket(UserSocket, "user_socket:#{contact.id}", %{contact_id: contact.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket, "mark_as_read", %{"message_ids" => [message.id]})

      assert_reply ref, :ok, %{}

      updated_message = MessageApp.Repo.get!(MessageApp.Groups.GroupMessage, message.id)
      assert updated_message.is_read == true
    end
  end
end
