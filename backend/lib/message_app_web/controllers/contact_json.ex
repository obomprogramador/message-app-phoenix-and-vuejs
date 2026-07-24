defmodule MessageAppWeb.ContactJSON do
  def render("index.json", %{contacts: contacts}) do
    last_messages = contacts.last_messages || %{}

    %{
      data: Enum.map(contacts.entries, &contact_json(&1, last_messages)),
      pagination: %{
        page: contacts.page,
        per_page: contacts.per_page,
        total: contacts.total,
        total_pages: contacts.total_pages
      }
    }
  end

  def render("show.json", %{contact: contact}) do
    %{data: contact_json(contact, %{})}
  end

  defp contact_json(contact, last_messages) do
    last_msg = Map.get(last_messages, contact.id)

    %{
      id: contact.id,
      name: contact.name,
      nickname: contact.nickname,
      avatar_url: contact.avatar_url,
      is_online: contact.is_online,
      last_message: if(last_msg, do: %{content: last_msg.content, timestamp: last_msg.timestamp}, else: nil)
    }
  end
end
