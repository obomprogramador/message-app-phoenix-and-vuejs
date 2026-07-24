import Ecto.Query

alias MessageApp.Repo
alias MessageApp.Contacts.{Contact, ContactLink}
alias MessageApp.Messages.Message

IO.puts("==> Seeding database...")

# --- 1. Contatos Padrao (usuarios) ---

default_users =
  for i <- 1..3 do
    attrs = %{
      name: "Usuario #{i}",
      nickname: "@usuario.#{i}",
      is_online: true
    }

    contact =
      case Repo.get_by(Contact, nickname: attrs.nickname) do
        nil ->
          %Contact{}
          |> Contact.changeset(attrs)
          |> Repo.insert!(on_conflict: :nothing)
          |> then(fn _ -> Repo.get_by!(Contact, nickname: attrs.nickname) end)

        existing ->
          IO.puts("   Usuario #{i} ja existe: #{existing.id}")
          existing
      end

    IO.puts("   Usuario #{i}: #{contact.id}")
    contact
  end

# --- 2. Contatos Disponiveis (para vincular) ---

available_contacts =
  for i <- 1..10 do
    attrs = %{
      name: "Contato #{i}",
      nickname: "@contato.#{i}",
      is_online: rem(i, 3) == 0
    }

    contact =
      case Repo.get_by(Contact, nickname: attrs.nickname) do
        nil ->
          %Contact{}
          |> Contact.changeset(attrs)
          |> Repo.insert!(on_conflict: :nothing)
          |> then(fn _ -> Repo.get_by!(Contact, nickname: attrs.nickname) end)

        existing ->
          existing
      end

    IO.puts("   Contato #{i}: #{contact.id}")
    contact
  end

# --- 3. Vinculos (cada usuario com seus contatos) ---

IO.puts("   Criando vinculos...")

Enum.each(default_users, fn default_contact ->
  user_index = Enum.find_index(default_users, &(&1.id == default_contact.id))

  # Usuario 1 sempre recebe pelo menos 5 contatos vinculados
  count = if user_index == 0, do: 5, else: 3
  start_idx = rem(user_index * 3, length(available_contacts))

  linked_for_user =
    for j <- 0..(count - 1) do
      idx = rem(start_idx + j, length(available_contacts))
      Enum.at(available_contacts, idx)
    end

  for linked <- linked_for_user do
    existing_link =
      Repo.one(
        from(cl in ContactLink,
          where: cl.default_contact_id == ^default_contact.id and cl.linked_contact_id == ^linked.id
        )
      )

    unless existing_link do
      # Via ida
      %ContactLink{}
      |> ContactLink.changeset(%{
        default_contact_id: default_contact.id,
        linked_contact_id: linked.id
      })
      |> Repo.insert!()

      # Via volta (reverso)
      existing_reverse =
        Repo.one(
          from(cl in ContactLink,
            where: cl.default_contact_id == ^linked.id and cl.linked_contact_id == ^default_contact.id
          )
        )

      unless existing_reverse do
        %ContactLink{}
        |> ContactLink.changeset(%{
          default_contact_id: linked.id,
          linked_contact_id: default_contact.id
        })
        |> Repo.insert!()
      end

      IO.puts("   Vinculo: #{default_contact.nickname} <-> #{linked.nickname}")
    end
  end
end)

# --- 3.1 Vinculos entre usuarios ---

IO.puts("   Criando vinculos entre usuarios...")

for user_a <- default_users, user_b <- default_users, user_a.id < user_b.id do
  existing_link =
    Repo.one(
      from(cl in ContactLink,
        where: cl.default_contact_id == ^user_a.id and cl.linked_contact_id == ^user_b.id
      )
    )

  unless existing_link do
    # Via ida
    %ContactLink{}
    |> ContactLink.changeset(%{
      default_contact_id: user_a.id,
      linked_contact_id: user_b.id
    })
    |> Repo.insert!()

    # Via volta (reverso)
    %ContactLink{}
    |> ContactLink.changeset(%{
      default_contact_id: user_b.id,
      linked_contact_id: user_a.id
    })
    |> Repo.insert!()

    IO.puts("   Vinculo: #{user_a.nickname} <-> #{user_b.nickname}")
  end
end

# --- 4. Mensagens ---

IO.puts("   Criando mensagens...")

# Mensagens entre usuarios (conversas reais)
for user_a <- default_users, user_b <- default_users, user_a.id < user_b.id do
  existing_msg_count =
    Repo.one(
      from(m in Message,
        where:
          (m.contact_id == ^user_a.id and m.from_contact_id == ^user_b.id) or
            (m.contact_id == ^user_b.id and m.from_contact_id == ^user_a.id),
        select: count(m.id)
      )
    )

  if existing_msg_count == 0 do
    messages_data = [
      %{
        contact_id: user_a.id,
        from_contact_id: user_b.id,
        content: "Ola #{user_a.name}, tudo bem?",
        direction: "received",
        is_read: true
      },
      %{
        contact_id: user_b.id,
        from_contact_id: user_a.id,
        content: "Oi #{user_b.name}, tudo sim! E voce?",
        direction: "received",
        is_read: true
      },
      %{
        contact_id: user_a.id,
        from_contact_id: user_b.id,
        content: "Tambem! Vamos marcar algo?",
        direction: "received",
        is_read: false
      }
    ]

    Enum.each(messages_data, fn attrs ->
      %Message{}
      |> Message.changeset(attrs)
      |> Repo.insert!()
    end)

    IO.puts("   Mensagens criadas: #{user_a.nickname} <-> #{user_b.nickname}")
  end
end

# Mensagens entre usuario e seus contatos
Enum.each(default_users, fn default_contact ->
  user_links =
    Repo.all(
      from(cl in ContactLink,
        where: cl.default_contact_id == ^default_contact.id,
        preload: [:linked_contact]
      )
    )

  non_user_links = Enum.filter(user_links, &(&1.linked_contact.nickname not in ["@usuario.1", "@usuario.2", "@usuario.3"]))

  first_link = List.first(non_user_links)

  if first_link do
    linked = first_link.linked_contact

    existing_msg_count =
      Repo.one(
        from(m in Message,
          where: m.contact_id == ^linked.id and m.from_contact_id == ^default_contact.id,
          select: count(m.id)
        )
      )

    if existing_msg_count == 0 do
      messages_data = [
        %{
          contact_id: linked.id,
          from_contact_id: default_contact.id,
          content: "Ola #{linked.name}!",
          direction: "received",
          is_read: true
        },
        %{
          contact_id: default_contact.id,
          from_contact_id: linked.id,
          content: "Oi #{default_contact.name}, tudo bem!",
          direction: "received",
          is_read: true
        },
        %{
          contact_id: linked.id,
          from_contact_id: default_contact.id,
          content: "Vamos marcar um cafe?",
          direction: "received",
          is_read: false
        }
      ]

      Enum.each(messages_data, fn attrs ->
        %Message{}
        |> Message.changeset(attrs)
        |> Repo.insert!()
      end)

      IO.puts("   Mensagens: #{default_contact.nickname} <-> #{linked.nickname}")
    end
  end
end)

IO.puts("==> Seed concluido!")
IO.puts("   Usuarios: #{length(default_users)}")
IO.puts("   Contatos disponiveis: #{length(available_contacts)}")
IO.puts("")
IO.puts("   Para testar conversas, acesse:")
for user <- default_users do
  IO.puts("   http://localhost:8080/#{user.id}  (#{user.nickname})")
end
