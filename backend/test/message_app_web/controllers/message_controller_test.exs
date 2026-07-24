defmodule MessageAppWeb.MessageControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/contacts/:contact_id/messages" do
    test "retorna mensagens do contato", %{conn: conn} do
      contact = insert(:contact)
      insert(:message, contact: contact, content: "Ola")
      insert(:message, contact: contact, content: "Oi")

      conn = get(conn, "/api/contacts/#{contact.id}/messages")

      assert %{"data" => data, "pagination" => pagination} = json_response(conn, 200)
      assert length(data) == 2
      assert pagination["total"] == 2
    end

    test "retorna lista vazia quando nao ha mensagens", %{conn: conn} do
      contact = insert(:contact)

      conn = get(conn, "/api/contacts/#{contact.id}/messages")

      assert %{"data" => []} = json_response(conn, 200)
    end
  end

  describe "POST /api/contacts/:contact_id/messages" do
    test "cria uma mensagem", %{conn: conn} do
      contact = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/contacts/#{contact.id}/messages", %{
        "message" => %{
          "content" => "Ola, tudo bem?",
          "direction" => "sent"
        }
      })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["content"] == "Ola, tudo bem?"
      assert data["direction"] == "sent"
      assert data["is_read"] == false
    end

    test "retorna erro para dados invalidos", %{conn: conn} do
      contact = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/contacts/#{contact.id}/messages", %{
        "message" => %{"content" => nil, "direction" => nil}
      })

      assert json_response(conn, 422)
    end
  end

  describe "GET /api/contacts/:contact_id/messages/search" do
    test "busca mensagens por conteudo", %{conn: conn} do
      contact = insert(:contact)
      insert(:message, contact: contact, content: "Arquivo enviado")
      insert(:message, contact: contact, content: "Outra mensagem")

      conn = get(conn, "/api/contacts/#{contact.id}/messages/search", %{"q" => "arquivo"})

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 1
      assert hd(data)["content"] == "Arquivo enviado"
    end
  end

  describe "PATCH /api/messages/:id/read" do
    test "marca mensagem como lida", %{conn: conn} do
      message = insert(:message, is_read: false)

      conn = patch(conn, "/api/messages/#{message.id}/read")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["is_read"] == true
    end

    test "retorna 404 para mensagem inexistente", %{conn: conn} do
      id = Ecto.UUID.generate()
      conn = patch(conn, "/api/messages/#{id}/read")

      assert json_response(conn, 404)
    end
  end
end
