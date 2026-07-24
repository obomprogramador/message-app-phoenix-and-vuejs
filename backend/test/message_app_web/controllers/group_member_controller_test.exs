defmodule MessageAppWeb.GroupMemberControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/groups/:group_id/members" do
    test "retorna membros do grupo", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact)

      conn = get(conn, "/api/groups/#{group.id}/members")

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 1
    end
  end

  describe "POST /api/groups/:group_id/members" do
    test "adiciona membro ao grupo", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/members", %{
        "member" => %{"contact_id" => contact.id}
      })

      assert %{"data" => _data} = json_response(conn, 201)
    end

    test "adiciona membro com role especifica", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/members", %{
        "member" => %{"contact_id" => contact.id, "role" => "admin"}
      })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["role"] == "admin"
    end

    test "retorna erro para membro duplicado", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)

      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/members", %{
        "member" => %{"contact_id" => contact.id}
      })
      |> json_response(201)

      conn2 = build_conn()
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/members", %{
        "member" => %{"contact_id" => contact.id}
      })

      assert json_response(conn2, 422)
    end
  end

  describe "PATCH /api/groups/:group_id/members/:contact_id" do
    test "atualiza role do membro", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact, role: "member")

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> patch("/api/groups/#{group.id}/members/#{contact.id}", %{
        "member" => %{"role" => "admin"}
      })

      assert %{"data" => data} = json_response(conn, 200)
      assert data["role"] == "admin"
    end
  end

  describe "DELETE /api/groups/:group_id/members/:contact_id" do
    test "remove membro do grupo", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)
      insert(:group_member, group: group, contact: contact)

      conn = delete(conn, "/api/groups/#{group.id}/members/#{contact.id}")

      assert response(conn, 204)
    end

    test "retorna 404 quando membro nao existe", %{conn: conn} do
      group = insert(:group)
      contact = insert(:contact)

      conn = delete(conn, "/api/groups/#{group.id}/members/#{contact.id}")

      assert json_response(conn, 404)
    end
  end
end
