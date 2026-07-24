defmodule MessageAppWeb.MessageJSON do
  def render("index.json", %{messages: messages}) do
    %{
      data: Enum.map(messages.entries, &message_json/1),
      pagination: %{
        page: messages.page,
        per_page: messages.per_page,
        total: messages.total,
        total_pages: messages.total_pages
      }
    }
  end

  def render("show.json", %{message: message}) do
    %{data: message_json(message)}
  end

  defp message_json(message) do
    %{
      id: message.id,
      content: message.content,
      direction: message.direction,
      is_read: message.is_read,
      contact_id: message.contact_id,
      from_contact_id: message.from_contact_id,
      inserted_at: message.inserted_at,
      updated_at: message.updated_at
    }
  end
end
