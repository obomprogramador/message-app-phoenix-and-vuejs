defmodule MessageAppWeb.MessageChannel do
  use MessageAppWeb, :channel

  alias MessageApp.Messages
  alias MessageApp.Repo

  @impl true
  def join("messages:" <> contact_id, _params, socket) do
    if socket.assigns.contact_id == contact_id do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content, "direction" => direction}, socket) do
    attrs = %{
      content: content,
      direction: direction,
      contact_id: socket.assigns.contact_id,
      from_contact_id: socket.assigns.contact_id
    }

    case Messages.send_message(attrs) do
      {:ok, message} ->
        message = Repo.preload(message, [:contact, :from_contact])

        broadcast!(socket, "new_message", %{
          id: message.id,
          content: message.content,
          direction: message.direction,
          is_read: message.is_read,
          contact_id: message.contact_id,
          from_contact_id: message.from_contact_id,
          inserted_at: message.inserted_at,
          updated_at: message.updated_at
        })

        {:reply, {:ok, message_id(message)}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: errors_from_changeset(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("mark_as_read", %{"message_ids" => message_ids}, socket) when is_list(message_ids) do
    Enum.each(message_ids, fn id -> Messages.mark_as_read(id) end)
    broadcast!(socket, "messages_read", %{message_ids: message_ids})
    {:reply, :ok, socket}
  end

  @impl true
  def handle_info({:new_message, message_payload}, socket) do
    broadcast!(socket, "new_message", message_payload)
    {:noreply, socket}
  end

  defp message_id(message), do: %{id: message.id}

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
