defmodule MessageAppWeb.GroupController do
  use MessageAppWeb, :controller

  alias MessageApp.Groups

  action_fallback MessageAppWeb.FallbackController

  def index(conn, params) do
    groups = Groups.list_groups(params)
    render(conn, :index, groups: groups)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, group} <- Groups.get_group(id) do
      render(conn, :show, group: group)
    end
  end

  def create(conn, %{"group" => group_params} = params) do
    created_by_id = params["created_by_id"] || Map.get(group_params, "created_by_id")
    group_params = if created_by_id, do: Map.put(group_params, "created_by_id", created_by_id), else: group_params

    with {:ok, group} <- Groups.create_group(group_params) do
      conn
      |> put_status(:created)
      |> render(:show, group: group)
    end
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    with {:ok, group} <- Groups.get_group(id),
         {:ok, group} <- Groups.update_group(group, group_params) do
      render(conn, :show, group: group)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, group} <- Groups.get_group(id),
         {:ok, _} <- Groups.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end
end
