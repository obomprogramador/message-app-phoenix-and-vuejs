defmodule MessageApp.MessagesTest do
  use MessageApp.DataCase, async: true

  alias MessageApp.Messages
  alias MessageApp.Messages.Message

  describe "list_messages/2" do
    test "retorna mensagens de um contato" do
      contact = insert(:contact)
      insert(:message, contact: contact, content: "Ola")
      insert(:message, contact: contact, content: "Oi")

      result = Messages.list_messages(contact.id)

      assert length(result.entries) == 2
    end

    test "retorna mensagens ordenadas por data crescente" do
      contact = insert(:contact)
      msg1 = insert(:message, contact: contact, content: "Primeira", inserted_at: ~U[2025-01-01 00:00:00Z])
      msg2 = insert(:message, contact: contact, content: "Segunda", inserted_at: ~U[2025-01-02 00:00:00Z])

      result = Messages.list_messages(contact.id)

      assert length(result.entries) == 2
      assert hd(result.entries).id == msg1.id
      assert List.last(result.entries).id == msg2.id
    end

    test "nao retorna mensagens de outros contatos" do
      contact1 = insert(:contact)
      contact2 = insert(:contact)
      insert(:message, contact: contact1, content: "Ola")
      insert(:message, contact: contact2, content: "Oi")

      result = Messages.list_messages(contact1.id)

      assert length(result.entries) == 1
    end
  end

  describe "send_message/1" do
    test "cria uma mensagem" do
      contact = insert(:contact)

      attrs = %{
        content: "Ola, tudo bem?",
        direction: "sent",
        contact_id: contact.id
      }

      assert {:ok, %Message{} = message} = Messages.send_message(attrs)
      assert message.content == "Ola, tudo bem?"
      assert message.direction == "sent"
      assert message.is_read == false
    end

    test "retorna erro para dados invalidos" do
      attrs = %{content: nil, direction: nil, contact_id: nil}

      assert {:error, %Ecto.Changeset{}} = Messages.send_message(attrs)
    end

    test "retorna erro para direction invalida" do
      contact = insert(:contact)

      attrs = %{
        content: "Ola",
        direction: "invalid",
        contact_id: contact.id
      }

      assert {:error, %Ecto.Changeset{}} = Messages.send_message(attrs)
    end
  end

  describe "mark_as_read/1" do
    test "marca mensagem como lida" do
      message = insert(:message, is_read: false)

      assert {:ok, updated} = Messages.mark_as_read(message.id)
      assert updated.is_read == true
    end

    test "retorna erro para mensagem inexistente" do
      assert {:error, :not_found} = Messages.mark_as_read(Ecto.UUID.generate())
    end
  end

  describe "search_messages/3" do
    test "busca mensagens por conteudo" do
      contact = insert(:contact)
      insert(:message, contact: contact, content: "Arquivo enviado")
      insert(:message, contact: contact, content: "Outra mensagem")

      result = Messages.search_messages(contact.id, "arquivo")

      assert length(result.entries) == 1
      assert hd(result.entries).content == "Arquivo enviado"
    end

    test "retorna lista vazia para busca sem resultado" do
      contact = insert(:contact)

      result = Messages.search_messages(contact.id, "inexistente")

      assert result.entries == []
    end
  end

end
