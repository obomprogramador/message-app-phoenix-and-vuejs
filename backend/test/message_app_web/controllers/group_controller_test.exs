defmodule MessageAppWeb.GroupControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/groups" do
    test "retorna lista de grupos", %{conn: conn} do
      insert(:group)
      insert(:group)

      conn = get(conn, "/api/groups")

      assert %{"data" => data, "pagination" => pagination} = json_response(conn, 200)
      assert length(data) == 2
      assert pagination["total"] == 2
    end

    test "filtra por busca", %{conn: conn} do
      insert(:group, name: "Trabalho")
      insert(:group, name: "Familia")

      conn = get(conn, "/api/groups", %{"search" => "Trabalho"})

      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) == 1
      assert hd(data)["name"] == "Trabalho"
    end
  end

  describe "GET /api/groups/:id" do
    test "retorna grupo por ID", %{conn: conn} do
      group = insert(:group)

      conn = get(conn, "/api/groups/#{group.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == group.id
      assert data["name"] == group.name
    end

    test "retorna 404 para ID inexistente", %{conn: conn} do
      id = Ecto.UUID.generate()
      conn = get(conn, "/api/groups/#{id}")

      assert json_response(conn, 404)
    end
  end

  describe "POST /api/groups" do
    test "cria um grupo", %{conn: conn} do
      creator = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups", %{
        "group" => %{
          "name" => "Grupo Trabalho",
          "description" => "Discussoes",
          "created_by_id" => creator.id
        }
      })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "Grupo Trabalho"
    end

    test "retorna erro para dados invalidos", %{conn: conn} do
      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups", %{
        "group" => %{"name" => nil, "created_by_id" => nil}
      })

      assert json_response(conn, 422)
    end
  end

  describe "PATCH /api/groups/:id" do
    test "atualiza dados do grupo", %{conn: conn} do
      group = insert(:group)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> patch("/api/groups/#{group.id}", %{
        "group" => %{"name" => "Novo Nome"}
      })

      assert %{"data" => data} = json_response(conn, 200)
      assert data["name"] == "Novo Nome"
    end
  end

  describe "DELETE /api/groups/:id" do
    test "deleta o grupo", %{conn: conn} do
      group = insert(:group)

      conn = delete(conn, "/api/groups/#{group.id}")

      assert response(conn, 204)
    end
  end
end
