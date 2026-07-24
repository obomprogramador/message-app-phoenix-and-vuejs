defmodule MessageAppWeb.GroupMessageControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/groups/:group_id/messages" do
    test "retorna mensagens do grupo", %{conn: conn} do
      group = insert(:group)
      sender = insert(:contact)
      insert(:group_message, group: group, sender: sender)
      insert(:group_message, group: group, sender: sender)

      conn = get(conn, "/api/groups/#{group.id}/messages")

      assert %{"data" => data, "pagination" => pagination} = json_response(conn, 200)
      assert length(data) == 2
      assert pagination["total"] == 2
    end
  end

  describe "POST /api/groups/:group_id/messages" do
    test "envia mensagem no grupo", %{conn: conn} do
      group = insert(:group)
      sender = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/messages", %{
        "message" => %{
          "content" => "Ola pessoal!",
          "sender_id" => sender.id
        }
      })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["content"] == "Ola pessoal!"
      assert data["group_id"] == group.id
      assert data["sender_id"] == sender.id
    end

    test "retorna erro para dados invalidos", %{conn: conn} do
      group = insert(:group)
      sender = insert(:contact)

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/groups/#{group.id}/messages", %{
        "message" => %{"content" => nil, "sender_id" => sender.id}
      })

      assert json_response(conn, 422)
    end
  end
end
