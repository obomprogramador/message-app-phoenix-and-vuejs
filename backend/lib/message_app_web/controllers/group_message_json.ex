defmodule MessageAppWeb.GroupMessageJSON do
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
    sender = Map.get(message, :sender)

    %{
      id: message.id,
      content: message.content,
      is_read: message.is_read,
      group_id: message.group_id,
      sender_id: message.sender_id,
      sender: if(sender, do: %{id: sender.id, name: sender.name, nickname: sender.nickname, avatar_url: sender.avatar_url}, else: nil),
      inserted_at: message.inserted_at,
      updated_at: message.updated_at
    }
  end
end
