defmodule MessageAppWeb.ContactControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/contacts" do
    test "retorna lista de contatos vinculados", %{conn: conn} do
      default = insert(:contact)
      linked = insert(:contact)
      MessageApp.Contacts.link_contact(default.id, linked.id)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> get("/api/contacts", %{"default_contact_id" => default.id})

      assert %{"data" => data, "pagination" => pagination} = json_response(conn, 200)
      assert length(data) == 1
      assert pagination["total"] == 1
    end

    test "retorna pagina vazia quando nao ha vinculos", %{conn: conn} do
      default = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> get("/api/contacts", %{"default_contact_id" => default.id})

      assert %{"data" => [], "pagination" => pagination} = json_response(conn, 200)
      assert pagination["total"] == 0
    end
  end

  describe "GET /api/contacts/:id" do
    test "retorna contato por ID", %{conn: conn} do
      contact = insert(:contact)

      conn = get(conn, "/api/contacts/#{contact.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == contact.id
      assert data["name"] == contact.name
    end

    test "retorna 404 para ID inexistente", %{conn: conn} do
      id = Ecto.UUID.generate()
      conn = get(conn, "/api/contacts/#{id}")

      assert json_response(conn, 404)
    end
  end

  describe "POST /api/contacts" do
    test "cria vinculo entre contatos", %{conn: conn} do
      default = insert(:contact)
      linked = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/contacts", %{
        "default_contact_id" => default.id,
        "contact" => %{"linked_contact_id" => linked.id}
      })

      assert json_response(conn, 201)
    end

    test "retorna erro para vinculo duplicado", %{conn: conn} do
      default = insert(:contact)
      linked = insert(:contact)

      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/contacts", %{
        "default_contact_id" => default.id,
        "contact" => %{"linked_contact_id" => linked.id}
      })
      |> json_response(201)

      conn2 = build_conn()
      |> put_req_header("content-type", "application/json")
      |> post("/api/contacts", %{
        "default_contact_id" => default.id,
        "contact" => %{"linked_contact_id" => linked.id}
      })

      assert json_response(conn2, 422)
    end
  end

  describe "DELETE /api/contacts/:id" do
    test "remove vinculo entre contatos", %{conn: conn} do
      default = insert(:contact)
      linked = insert(:contact)
      MessageApp.Contacts.link_contact(default.id, linked.id)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> delete("/api/contacts/#{linked.id}", %{"default_contact_id" => default.id})

      assert response(conn, 204)
    end

    test "retorna 404 quando vinculo nao existe", %{conn: conn} do
      default = insert(:contact)
      linked = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> delete("/api/contacts/#{linked.id}", %{"default_contact_id" => default.id})

      assert json_response(conn, 404)
    end
  end
end
