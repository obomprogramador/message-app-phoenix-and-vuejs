defmodule MessageAppWeb.GroupChannel do
  use MessageAppWeb, :channel

  alias MessageApp.Groups
  alias MessageApp.Repo

  @impl true
  def join("group:" <> group_id, _params, socket) do
    case Groups.get_group(group_id) do
      {:ok, group} ->
        is_member = Enum.any?(group.group_members, fn m -> m.contact_id == socket.assigns.contact_id end)

        if is_member do
          {:ok, socket}
        else
          {:error, %{reason: "unauthorized"}}
        end

      {:error, :not_found} ->
        {:error, %{reason: "group not found"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    group_id = topic_group_id(socket.topic)

    case Groups.send_group_message(group_id, socket.assigns.contact_id, %{"content" => content}) do
      {:ok, message} ->
        message = Repo.preload(message, [:sender])

        broadcast!(socket, "new_message", %{
          id: message.id,
          content: message.content,
          is_read: message.is_read,
          group_id: message.group_id,
          sender_id: message.sender_id,
          sender: %{
            id: message.sender.id,
            name: message.sender.name,
            nickname: message.sender.nickname,
            avatar_url: message.sender.avatar_url
          },
          inserted_at: message.inserted_at,
          updated_at: message.updated_at
        })

        {:reply, {:ok, %{id: message.id}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: errors_from_changeset(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("mark_as_read", %{"message_ids" => message_ids}, socket) when is_list(message_ids) do
    Enum.each(message_ids, fn id -> Groups.mark_group_message_as_read(id) end)
    broadcast!(socket, "messages_read", %{message_ids: message_ids})
    {:reply, :ok, socket}
  end

  @impl true
  def handle_info({:new_message, message_payload}, socket) do
    broadcast!(socket, "new_message", message_payload)
    {:noreply, socket}
  end

  defp topic_group_id("group:" <> id), do: id

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
