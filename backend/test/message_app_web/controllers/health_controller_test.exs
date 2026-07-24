defmodule MessageAppWeb.HealthControllerTest do
  use MessageAppWeb.ConnCase

  describe "GET /api/health" do
    test "returns status ok", %{conn: conn} do
      conn = get(conn, "/api/health")

      assert json_response(conn, 200)["status"] == "ok"
    end
  end
end
