defmodule MessageAppWeb.ChannelsIntegrationTest do
  use MessageAppWeb.ChannelCase

  alias MessageAppWeb.UserSocket

  describe "dois clientes no mesmo grupo" do
    setup do
      contact_a = insert(:contact)
      contact_b = insert(:contact)
      group = insert(:group, created_by: contact_a)

      insert(:group_member, group: group, contact: contact_a, role: "member")
      insert(:group_member, group: group, contact: contact_b, role: "member")

      %{contact_a: contact_a, contact_b: contact_b, group: group}
    end

    test "ambos conseguem join no mesmo grupo", %{contact_a: a, contact_b: b, group: group} do
      {:ok, _, socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{group.id}")

      {:ok, _, socket_b} =
        socket(UserSocket, "user_socket:#{b.id}", %{contact_id: b.id})
        |> subscribe_and_join("group:#{group.id}")

      assert socket_a.assigns.contact_id == a.id
      assert socket_b.assigns.contact_id == b.id
    end

    test "mensagem enviada por A chega via broadcast", %{contact_a: a, group: group} do
      {:ok, _, socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket_a, "new_message", %{"content" => "Oi do A"})

      assert_reply ref, :ok, %{id: message_id}

      assert_broadcast "new_message", %{content: "Oi do A", sender_id: sender_id, id: ^message_id}
      assert sender_id == a.id

      msg = MessageApp.Repo.get!(MessageApp.Groups.GroupMessage, message_id)
      assert msg.content == "Oi do A"
      assert msg.sender_id == a.id
      assert msg.group_id == group.id
    end

    test "mensagem enviada por B tambem funciona", %{contact_b: b, group: group} do
      {:ok, _, socket_b} =
        socket(UserSocket, "user_socket:#{b.id}", %{contact_id: b.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket_b, "new_message", %{"content" => "Oi do B"})

      assert_reply ref, :ok, %{id: message_id}

      assert_broadcast "new_message", %{content: "Oi do B", sender_id: sender_id, id: ^message_id}
      assert sender_id == b.id
    end

    test "mark_as_read atualiza mensagem no banco", %{contact_a: a, contact_b: b, group: group} do
      message = insert(:group_message, group: group, sender: b, is_read: false)

      {:ok, _, socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{group.id}")

      ref = push(socket_a, "mark_as_read", %{"message_ids" => [message.id]})

      assert_reply ref, :ok, %{}

      updated = MessageApp.Repo.get!(MessageApp.Groups.GroupMessage, message.id)
      assert updated.is_read == true
    end
  end

  describe "dois clientes em conversas diretas" do
    setup do
      contact_a = insert(:contact)
      contact_b = insert(:contact)
      %{contact_a: contact_a, contact_b: contact_b}
    end

    test "B recebe mensagem via PubSub simulando HTTP do controller", %{contact_b: b} do
      {:ok, _, _socket_b} =
        socket(UserSocket, "user_socket:#{b.id}", %{contact_id: b.id})
        |> subscribe_and_join("messages:#{b.id}")

      payload = %{
        id: Ecto.UUID.generate(),
        content: "Msg via HTTP",
        direction: "received",
        is_read: false,
        contact_id: b.id,
        from_contact_id: Ecto.UUID.generate(),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      Phoenix.PubSub.broadcast(
        MessageApp.PubSub,
        "messages:#{b.id}",
        {:new_message, payload}
      )

      assert_push "new_message", ^payload
    end

    test "A nao recebe mensagem destinada a B", %{contact_a: a, contact_b: b} do
      {:ok, _, _socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("messages:#{a.id}")

      payload = %{
        id: Ecto.UUID.generate(),
        content: "Msg para B",
        direction: "received",
        is_read: false,
        contact_id: b.id,
        from_contact_id: a.id,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      Phoenix.PubSub.broadcast(
        MessageApp.PubSub,
        "messages:#{b.id}",
        {:new_message, payload}
      )

      refute_receive {:new_message, _}, 100
    end

    test "mensagem enviada via canal faz broadcast no topic do remetente", %{contact_a: a} do
      {:ok, _, socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("messages:#{a.id}")

      ref = push(socket_a, "new_message", %{"content" => "Hello", "direction" => "sent"})

      assert_reply ref, :ok, %{id: message_id}

      assert_broadcast "new_message", %{content: "Hello", id: ^message_id}

      msg = MessageApp.Repo.get!(MessageApp.Messages.Message, message_id)
      assert msg.content == "Hello"
      assert msg.direction == "sent"
      assert msg.from_contact_id == a.id
    end
  end

  describe "desconectando um cliente" do
    setup do
      contact_a = insert(:contact)
      contact_b = insert(:contact)
      group = insert(:group, created_by: contact_a)

      insert(:group_member, group: group, contact: contact_a, role: "member")
      insert(:group_member, group: group, contact: contact_b, role: "member")

      %{contact_a: contact_a, contact_b: contact_b, group: group}
    end

    test "cliente que faz leave nao recebe mais broadcasts", %{contact_a: a, contact_b: b, group: group} do
      Process.flag(:trap_exit, true)

      {:ok, _, socket_a} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{group.id}")

      {:ok, _, socket_b} =
        socket(UserSocket, "user_socket:#{b.id}", %{contact_id: b.id})
        |> subscribe_and_join("group:#{group.id}")

      leave(socket_b)
      assert_receive {:EXIT, _, _}

      push(socket_a, "new_message", %{"content" => "Depois do leave"})

      refute_receive {:new_message, _}, 100

      msg = MessageApp.Repo.all(MessageApp.Groups.GroupMessage) |> List.last()
      assert msg.content == "Depois do leave"
    end
  end

  describe "troca de conversa" do
    setup do
      contact_a = insert(:contact)
      contact_b = insert(:contact)
      contact_c = insert(:contact)

      group_ab = insert(:group, created_by: contact_a)
      insert(:group_member, group: group_ab, contact: contact_a, role: "member")
      insert(:group_member, group: group_ab, contact: contact_b, role: "member")

      group_ac = insert(:group, created_by: contact_a)
      insert(:group_member, group: group_ac, contact: contact_a, role: "member")
      insert(:group_member, group: group_ac, contact: contact_c, role: "member")

      %{contact_a: contact_a, group_ab: group_ab, group_ac: group_ac}
    end

    test "cliente faz leave de um grupo e join em outro", %{contact_a: a, group_ab: ab, group_ac: ac} do
      Process.flag(:trap_exit, true)

      {:ok, _, socket_ab} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{ab.id}")

      leave(socket_ab)
      assert_receive {:EXIT, _, _}

      {:ok, _, socket_ac} =
        socket(UserSocket, "user_socket:#{a.id}", %{contact_id: a.id})
        |> subscribe_and_join("group:#{ac.id}")

      push(socket_ac, "new_message", %{"content" => "Msg no grupo AC"})

      assert_broadcast "new_message", %{content: "Msg no grupo AC"}
    end
  end
end
