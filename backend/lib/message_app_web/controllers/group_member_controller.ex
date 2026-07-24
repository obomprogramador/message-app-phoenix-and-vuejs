defmodule MessageAppWeb.GroupMemberController do
  use MessageAppWeb, :controller

  alias MessageApp.Groups

  action_fallback MessageAppWeb.FallbackController

  def index(conn, %{"group_id" => group_id} = params) do
    members = Groups.list_group_members(group_id, params)
    render(conn, :index, members: members)
  end

  def create(conn, %{"group_id" => group_id, "member" => %{"contact_id" => contact_id} = member_params}) do
    role = Map.get(member_params, "role", "member")

    with {:ok, member} <- Groups.add_group_member(group_id, contact_id, role) do
      conn
      |> put_status(:created)
      |> render(:show, member: member)
    end
  end

  def update(conn, %{"group_id" => group_id, "contact_id" => contact_id, "member" => member_params}) do
    role = Map.get(member_params, "role", "member")

    with {:ok, _} <- Groups.update_group_member_role(group_id, contact_id, role) do
      member = %{group_id: group_id, contact_id: contact_id, role: role}
      render(conn, :show, member: member)
    end
  end

  def delete(conn, %{"group_id" => group_id, "contact_id" => contact_id}) do
    with {:ok, _} <- Groups.remove_group_member(group_id, contact_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
