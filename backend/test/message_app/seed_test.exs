defmodule MessageApp.SeedTest do
  use MessageApp.DataCase, async: false

  import Ecto.Query

  alias MessageApp.Repo
  alias MessageApp.Contacts.{Contact, ContactLink}
  alias MessageApp.Messages.Message

  describe "seed data" do
    setup do
      Code.eval_file("priv/repo/seeds.exs")
      :ok
    end

    test "cria 3 usuarios" do
      for i <- 1..3 do
        user = Repo.get_by(Contact, nickname: "@usuario.#{i}")
        assert user != nil
        assert user.name == "Usuario #{i}"
        assert user.is_online == true
      end
    end

    test "cria 10 contatos disponiveis" do
      for i <- 1..10 do
        contact = Repo.get_by(Contact, nickname: "@contato.#{i}")
        assert contact != nil
        assert contact.name == "Contato #{i}"
        assert contact.is_online == (rem(i, 3) == 0)
      end
    end

    test "usuario 1 tem 5 contatos vinculados" do
      user1 = Repo.get_by(Contact, nickname: "@usuario.1")

      contact_nicks = Enum.map(1..5, &"@contato.#{&1}")

      links =
        Repo.all(
          from(cl in ContactLink, where: cl.default_contact_id == ^user1.id)
        )
        |> Enum.filter(fn cl ->
          linked = Repo.get(Contact, cl.linked_contact_id)
          linked.nickname in contact_nicks
        end)

      assert length(links) == 5
    end

    test "cria vinculos entre usuarios" do
      user1 = Repo.get_by(Contact, nickname: "@usuario.1")
      user2 = Repo.get_by(Contact, nickname: "@usuario.2")
      user3 = Repo.get_by(Contact, nickname: "@usuario.3")

      link_1_2 =
        Repo.one(
          from(cl in ContactLink,
            where: cl.default_contact_id == ^user1.id and cl.linked_contact_id == ^user2.id
          )
        )

      assert link_1_2 != nil

      link_1_3 =
        Repo.one(
          from(cl in ContactLink,
            where: cl.default_contact_id == ^user1.id and cl.linked_contact_id == ^user3.id
          )
        )

      assert link_1_3 != nil

      link_2_3 =
        Repo.one(
          from(cl in ContactLink,
            where: cl.default_contact_id == ^user2.id and cl.linked_contact_id == ^user3.id
          )
        )

      assert link_2_3 != nil
    end

    test "cria mensagens entre usuarios" do
      user1 = Repo.get_by(Contact, nickname: "@usuario.1")
      user2 = Repo.get_by(Contact, nickname: "@usuario.2")

      messages =
        Repo.all(
          from(m in Message,
            where:
              (m.contact_id == ^user1.id and m.from_contact_id == ^user2.id) or
                (m.contact_id == ^user2.id and m.from_contact_id == ^user1.id)
          )
        )

      assert length(messages) == 3
    end

    test "cria mensagens entre usuario e seu primeiro contato" do
      user1 = Repo.get_by(Contact, nickname: "@usuario.1")

      first_link =
        Repo.one(
          from(cl in ContactLink,
            where: cl.default_contact_id == ^user1.id,
            order_by: [asc: cl.inserted_at],
            limit: 1
          )
        )

      if first_link do
        linked = Repo.get(Contact, first_link.linked_contact_id)

        messages =
          Repo.all(
            from(m in Message,
              where:
                (m.contact_id == ^linked.id and m.from_contact_id == ^user1.id) or
                  (m.contact_id == ^user1.id and m.from_contact_id == ^linked.id)
            )
          )

        assert length(messages) == 3
      end
    end

    test "seed e idempotente" do
      contacts_before = Repo.aggregate(Contact, :count, :id)
      links_before = Repo.aggregate(ContactLink, :count, :id)
      messages_before = Repo.aggregate(Message, :count, :id)

      Code.eval_file("priv/repo/seeds.exs")

      contacts_after = Repo.aggregate(Contact, :count, :id)
      links_after = Repo.aggregate(ContactLink, :count, :id)
      messages_after = Repo.aggregate(Message, :count, :id)

      assert contacts_before == contacts_after
      assert links_before == links_after
      assert messages_before == messages_after
    end
  end
end
