defmodule MessageApp.ContactsTest do
  use MessageApp.DataCase, async: true

  alias MessageApp.Contacts

  describe "list_contacts/1" do
    test "retorna contatos vinculados" do
      default = insert(:contact)
      linked = insert(:contact)

      Contacts.link_contact(default.id, linked.id)

      result = Contacts.list_contacts(%{default_contact_id: default.id})

      assert length(result.entries) == 1
      assert hd(result.entries).id == linked.id
    end

    test "retorna pagina vazia quando nao ha vinculos" do
      default = insert(:contact)

      result = Contacts.list_contacts(%{default_contact_id: default.id})

      assert result.entries == []
      assert result.total == 0
    end

    test "filtra por busca" do
      default = insert(:contact)
      pedro = insert(:contact, name: "Pedro Santos")
      lucas = insert(:contact, name: "Lucas Souza")

      Contacts.link_contact(default.id, pedro.id)
      Contacts.link_contact(default.id, lucas.id)

      result = Contacts.list_contacts(%{default_contact_id: default.id, search: "Pedro"})

      assert length(result.entries) == 1
      assert hd(result.entries).name == "Pedro Santos"
    end

    test "retorna metadados de paginacao" do
      default = insert(:contact)

      result = Contacts.list_contacts(%{default_contact_id: default.id})

      assert result.page == 1
      assert result.per_page == 20
      assert result.total == 0
      assert result.total_pages == 0
    end
  end

  describe "get_contact/2" do
    test "retorna {:ok, contato}" do
      contact = insert(:contact)

      assert {:ok, result} = Contacts.get_contact(contact.id)
      assert result.id == contact.id
    end

    test "retorna {:error, :not_found} para ID inexistente" do
      assert {:error, :not_found} = Contacts.get_contact(Ecto.UUID.generate())
    end
  end

  describe "link_contact/2" do
    test "cria vinculo entre contatos" do
      default = insert(:contact)
      linked = insert(:contact)

      assert {:ok, _} = Contacts.link_contact(default.id, linked.id)
    end

    test "retorna erro para vinculo duplicado" do
      default = insert(:contact)
      linked = insert(:contact)

      assert {:ok, _} = Contacts.link_contact(default.id, linked.id)
      assert {:error, _} = Contacts.link_contact(default.id, linked.id)
    end
  end

  describe "unlink_contact/2" do
    test "remove vinculo entre contatos" do
      default = insert(:contact)
      linked = insert(:contact)

      Contacts.link_contact(default.id, linked.id)

      assert {:ok, _} = Contacts.unlink_contact(default.id, linked.id)
    end

    test "retorna erro quando vinculo nao existe" do
      default = insert(:contact)
      linked = insert(:contact)

      assert {:error, :not_found} = Contacts.unlink_contact(default.id, linked.id)
    end
  end

  describe "find_contact_by_nickname/1" do
    test "retorna {:ok, contato} para nickname existente" do
      contact = insert(:contact, nickname: "@pedro.santos")

      assert {:ok, result} = Contacts.find_contact_by_nickname("@pedro.santos")
      assert result.id == contact.id
    end

    test "retorna {:error, :not_found} para nickname inexistente" do
      assert {:error, :not_found} = Contacts.find_contact_by_nickname("@inexistente")
    end
  end

end
