defmodule MessageApp.GroupsTest do
  use MessageApp.DataCase, async: true

  alias MessageApp.Groups
  alias MessageApp.Groups.{Group, GroupMember, GroupMessage}

  describe "list_groups/1" do
    test "retorna lista de grupos" do
      insert(:group)
      insert(:group)

      result = Groups.list_groups()

      assert length(result.entries) == 2
    end

    test "filtra por busca" do
      insert(:group, name: "Grupo Trabalho")
      insert(:group, name: "Grupo Familia")

      result = Groups.list_groups(%{search: "Trabalho"})

      assert length(result.entries) == 1
      assert hd(result.entries).name == "Grupo Trabalho"
    end

    test "retorna metadados de paginacao" do
      result = Groups.list_groups()

      assert result.page == 1
      assert result.per_page == 20
      assert result.total == 0
      assert result.total_pages == 0
    end
  end

  describe "get_group/1" do
    test "retorna {:ok, grupo}" do
      group = insert(:group)

      assert {:ok, result} = Groups.get_group(group.id)
      assert result.id == group.id
    end

    test "retorna {:error, :not_found} para ID inexistente" do
      assert {:error, :not_found} = Groups.get_group(Ecto.UUID.generate())
    end
  end

  describe "create_group/1" do
    test "cria um grupo com dados validos" do
      creator = insert(:contact)

      attrs = %{
        name: "Grupo de Trabalho",
        description: "Discussoes do trabalho",
        created_by_id: creator.id
      }

      assert {:ok, %Group{} = group} = Groups.create_group(attrs)
      assert group.name == "Grupo de Trabalho"
      assert group.description == "Discussoes do trabalho"
      assert length(group.members) == 1
      assert hd(group.members).id == creator.id
    end

    test "cria um grupo com membros" do
      creator = insert(:contact)
      member1 = insert(:contact)
      member2 = insert(:contact)

      attrs = %{
        name: "Grupo Teste",
        created_by_id: creator.id,
        member_ids: [member1.id, member2.id]
      }

      assert {:ok, %Group{} = group} = Groups.create_group(attrs)
      assert group.name == "Grupo Teste"
      assert length(group.members) == 3
      member_ids = Enum.map(group.members, & &1.id)
      assert creator.id in member_ids
      assert member1.id in member_ids
      assert member2.id in member_ids
    end

    test "cria um grupo com criador ja presente em member_ids" do
      creator = insert(:contact)
      member1 = insert(:contact)

      attrs = %{
        name: "Grupo Teste",
        created_by_id: creator.id,
        member_ids: [creator.id, member1.id]
      }

      assert {:ok, %Group{} = group} = Groups.create_group(attrs)
      assert length(group.members) == 2
    end

    test "retorna erro para dados invalidos" do
      attrs = %{name: nil, created_by_id: nil}

      assert {:error, %Ecto.Changeset{}} = Groups.create_group(attrs)
    end
  end

  describe "update_group/2" do
    test "atualiza dados do grupo" do
      group = insert(:group)

      assert {:ok, updated} = Groups.update_group(group, %{name: "Novo Nome"})
      assert updated.name == "Novo Nome"
    end
  end

  describe "delete_group/1" do
    test "deleta o grupo" do
      group = insert(:group)

      assert {:ok, _} = Groups.delete_group(group)

      assert {:error, :not_found} = Groups.get_group(group.id)
    end
  end

  describe "list_group_members/2" do
    test "retorna membros do grupo" do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact)

      result = Groups.list_group_members(group.id)

      assert length(result.entries) == 1
    end
  end

  describe "add_group_member/3" do
    test "adiciona membro ao grupo" do
      group = insert(:group)
      contact = insert(:contact)

      assert {:ok, %GroupMember{}} = Groups.add_group_member(group.id, contact.id)
    end

    test "adiciona membro com role especifica" do
      group = insert(:group)
      contact = insert(:contact)

      assert {:ok, %GroupMember{} = member} =
               Groups.add_group_member(group.id, contact.id, "admin")

      assert member.role == "admin"
    end

    test "retorna erro para membro duplicado" do
      group = insert(:group)
      contact = insert(:contact)

      assert {:ok, _} = Groups.add_group_member(group.id, contact.id)
      assert {:error, _} = Groups.add_group_member(group.id, contact.id)
    end
  end

  describe "update_group_member_role/3" do
    test "atualiza role do membro" do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact, role: "member")

      assert {:ok, _} = Groups.update_group_member_role(group.id, contact.id, "admin")
    end

    test "retorna erro quando membro nao existe" do
      group = insert(:contact)

      assert {:error, :not_found} =
               Groups.update_group_member_role(group.id, Ecto.UUID.generate(), "admin")
    end
  end

  describe "remove_group_member/2" do
    test "remove membro do grupo" do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact)

      assert {:ok, _} = Groups.remove_group_member(group.id, contact.id)
    end

    test "retorna erro quando membro nao existe" do
      group = insert(:contact)

      assert {:error, :not_found} =
               Groups.remove_group_member(group.id, Ecto.UUID.generate())
    end
  end

  describe "list_group_messages/2" do
    test "retorna mensagens do grupo" do
      group = insert(:group)
      sender = insert(:contact)
      insert(:group_message, group: group, sender: sender)
      insert(:group_message, group: group, sender: sender)

      result = Groups.list_group_messages(group.id)

      assert length(result.entries) == 2
    end
  end

  describe "send_group_message/3" do
    test "envia mensagem no grupo" do
      group = insert(:group)
      sender = insert(:contact)

      attrs = %{content: "Ola pessoal!"}

      assert {:ok, %GroupMessage{} = message} =
               Groups.send_group_message(group.id, sender.id, attrs)

      assert message.content == "Ola pessoal!"
      assert message.group_id == group.id
      assert message.sender_id == sender.id
    end

    test "retorna erro para dados invalidos" do
      group = insert(:group)
      sender = insert(:contact)

      attrs = %{content: nil}

      assert {:error, %Ecto.Changeset{}} =
               Groups.send_group_message(group.id, sender.id, attrs)
    end
  end
end
