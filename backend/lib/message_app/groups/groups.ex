defmodule MessageApp.Groups do
  @moduledoc """
  Contexto para gerenciamento de grupos.
  """

  import Ecto.Query

  alias MessageApp.Repo
  alias MessageApp.Groups.{Group, GroupMember, GroupMessage}

  @default_page_size 20
  @max_page_size 100

  # --- Groups ---

  @doc """
  Lista grupos com paginacao.
  """
  def list_groups(params \\ %{}) do
    Group
    |> apply_group_filters(params)
    |> preload([:created_by, :members])
    |> order_by([g], asc: g.name)
    |> paginate(params)
  end

  @doc """
  Busca grupo por ID.
  """
  def get_group(id) do
    case Repo.get(Group, id) do
      nil -> {:error, :not_found}
      group -> {:ok, Repo.preload(group, [:created_by, :group_members, :members])}
    end
  end

  @doc """
  Cria um grupo com membros em uma transacao.
  """
  def create_group(attrs) do
    Repo.transaction(fn ->
      member_ids = Map.get(attrs, :member_ids) || Map.get(attrs, "member_ids", [])
      created_by_id = Map.get(attrs, :created_by_id) || Map.get(attrs, "created_by_id")

      other_member_ids =
        if created_by_id, do: Enum.reject(member_ids, &(&1 == created_by_id)), else: member_ids

      attrs =
        attrs
        |> Map.delete(:member_ids)
        |> Map.delete("member_ids")

      with {:ok, group} <- %Group{} |> Group.changeset(attrs) |> Repo.insert(),
           {:ok, _admin} <- add_group_member(group.id, created_by_id, "admin"),
           {:ok, _members} <- add_members_to_group(group.id, other_member_ids) do
        Repo.preload(group, [:created_by, :members])
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Atualiza um grupo.
  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deleta um grupo.
  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  # --- Group Members ---

  @doc """
  Lista membros do grupo com paginacao.
  """
  def list_group_members(group_id, params \\ %{}) do
    GroupMember
    |> where([gm], gm.group_id == ^group_id)
    |> preload([:contact])
    |> order_by([gm], asc: gm.joined_at)
    |> paginate_members(params)
  end

  @doc """
  Adiciona membro ao grupo.
  """
  def add_group_member(group_id, contact_id, role \\ "member") do
    %GroupMember{}
    |> GroupMember.changeset(%{
      group_id: group_id,
      contact_id: contact_id,
      role: role
    })
    |> Repo.insert()
  end

  @doc """
  Atualiza role do membro.
  """
  def update_group_member_role(group_id, contact_id, role) do
    GroupMember
    |> where([gm], gm.group_id == ^group_id and gm.contact_id == ^contact_id)
    |> Repo.update_all(set: [role: role])
    |> case do
      {0, _} -> {:error, :not_found}
      {count, _} when count > 0 -> {:ok, count}
    end
  end

  @doc """
  Remove membro do grupo.
  """
  def remove_group_member(group_id, contact_id) do
    GroupMember
    |> where([gm], gm.group_id == ^group_id and gm.contact_id == ^contact_id)
    |> Repo.delete_all()
    |> case do
      {0, _} -> {:error, :not_found}
      {count, _} when count > 0 -> {:ok, count}
    end
  end

  # --- Group Messages ---

  @doc """
  Lista mensagens do grupo com paginacao.
  """
  def list_group_messages(group_id, params \\ %{}) do
    GroupMessage
    |> where([gm], gm.group_id == ^group_id)
    |> preload([:sender])
    |> order_by([gm], desc: gm.inserted_at)
    |> paginate_group_messages(params)
  end

  @doc """
  Envia mensagem no grupo.
  """
  def send_group_message(group_id, sender_id, attrs) do
    normalized =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("group_id", group_id)
      |> Map.put("sender_id", sender_id)

    %GroupMessage{}
    |> GroupMessage.changeset(normalized)
    |> Repo.insert()
  end

  def mark_group_message_as_read(id) do
    case Repo.get(GroupMessage, id) do
      nil -> {:error, :not_found}
      message -> message |> GroupMessage.changeset(%{is_read: true}) |> Repo.update()
    end
  end

  # --- Private ---

  defp add_members_to_group(group_id, member_ids) when is_list(member_ids) do
    member_ids
    |> Enum.reduce_while({:ok, []}, fn member_id, {:ok, acc} ->
      case add_group_member(group_id, member_id) do
        {:ok, member} -> {:cont, {:ok, [member | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  defp add_members_to_group(_group_id, _), do: {:ok, []}


  defp apply_group_filters(query, %{"contact_id" => contact_id}) when is_binary(contact_id) do
    import Ecto.Query
    query
    |> join(:inner, [g], gm in GroupMember, on: gm.group_id == g.id)
    |> where([g, gm], gm.contact_id == ^contact_id)
    |> distinct([g], g.id)
  end
  defp apply_group_filters(query, %{search: search}) when is_binary(search) and search != "" do
    where(query, [g], ilike(g.name, ^"%#{search}%"))
  end
  defp apply_group_filters(query, %{"search" => search}) when is_binary(search) and search != "" do
    where(query, [g], ilike(g.name, ^"%#{search}%"))
  end
  defp apply_group_filters(query, _), do: query


  defp paginate(query, params) do
    page = parse_page(params)
    per_page = parse_per_page(params)
    offset = (page - 1) * per_page

    total = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total: total,
      total_pages: calculate_total_pages(total, per_page)
    }
  end

  defp paginate_members(query, params) do
    page = parse_page(params)
    per_page = parse_per_page(params)
    offset = (page - 1) * per_page

    total = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total: total,
      total_pages: calculate_total_pages(total, per_page)
    }
  end

  defp paginate_group_messages(query, params) do
    page = parse_page(params)
    per_page = parse_per_page(params, 50, 200)
    offset = (page - 1) * per_page

    total = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total: total,
      total_pages: calculate_total_pages(total, per_page)
    }
  end


  defp parse_page(%{page: page}) when is_integer(page) and page > 0, do: page
  defp parse_page(%{"page" => page}) when is_binary(page) do
    case Integer.parse(page) do
      {p, _} when p > 0 -> p
      _ -> 1
    end
  end
  defp parse_page(_), do: 1


  defp parse_per_page(params, default \\ @default_page_size, max \\ @max_page_size) do
    per_page = Map.get(params, :per_page) || Map.get(params, "per_page")

    case per_page do
      pp when is_integer(pp) and pp > 0 -> min(pp, max)
      pp when is_binary(pp) ->
        case Integer.parse(pp) do
          {parsed, _} when parsed > 0 -> min(parsed, max)
          _ -> default
        end
      _ -> default
    end
  end


  defp calculate_total_pages(0, _), do: 0
  defp calculate_total_pages(total, per_page) do
    total
    |> div(per_page)
    |> then(&if rem(total, per_page) > 0, do: &1 + 1, else: &1)
  end
end
