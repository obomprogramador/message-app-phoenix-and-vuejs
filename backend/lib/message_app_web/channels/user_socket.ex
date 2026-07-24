defmodule MessageAppWeb.UserSocket do
  use Phoenix.Socket

  channel "messages:*", MessageAppWeb.MessageChannel
  channel "group:*", MessageAppWeb.GroupChannel

  @impl true
  def connect(%{"contact_id" => contact_id}, socket, _connect_info)
      when is_binary(contact_id) and contact_id != "" do
    {:ok, assign(socket, :contact_id, contact_id)}
  end

  def connect(_, _, _), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.contact_id}"
end
