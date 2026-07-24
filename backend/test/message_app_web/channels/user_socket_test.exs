defmodule MessageAppWeb.UserSocketTest do
  use MessageAppWeb.ChannelCase

  alias MessageAppWeb.UserSocket

  describe "connect/3" do
    test "conecta com contact_id valido" do
      contact = insert(:contact)

      assert {:ok, socket} =
               connect(UserSocket, %{"contact_id" => contact.id})

      assert socket.assigns.contact_id == contact.id
    end

    test "rejeita conexao sem contact_id" do
      assert :error = connect(UserSocket, %{})
    end

    test "rejeita conexao com contact_id vazio" do
      assert :error = connect(UserSocket, %{"contact_id" => ""})
    end
  end

  describe "id/1" do
    test "retorna id baseado no contact_id" do
      contact = insert(:contact)

      {:ok, socket} = connect(UserSocket, %{"contact_id" => contact.id})

      assert UserSocket.id(socket) == "user_socket:#{contact.id}"
    end
  end
end
