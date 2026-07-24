defmodule MessageApp.Contacts do
  @moduledoc """
  Contexto para gerenciamento de contatos.
  """

  import Ecto.Query

  alias MessageApp.Repo
  alias MessageApp.Contacts.{Contact, ContactLink}
  alias MessageApp.Messages.Message

  @default_page_size 20
  @max_page_size 100

  @doc """
  Lista contatos vinculados ao contato padrao com paginacao e filtros.
  """
  def list_contacts(params \\ %{}) do
    default_contact_id = fetch_default_contact_id(params)

    query =
      Contact
      |> join(:inner, [c], cl in ContactLink, on: cl.linked_contact_id == c.id)

    result =
      query
      |> maybe_add_default_contact_where(default_contact_id)
      |> apply_filters(params)
      |> paginate(params)

    if default_contact_id do
      contact_ids = Enum.map(result.entries, & &1.id)
      last_messages = get_last_messages(default_contact_id, contact_ids)
      %{result | last_messages: last_messages}
    else
      %{result | last_messages: %{}}
    end
  end

  @doc """
  Busca contato por ID com preloads.
  """
  def get_contact(id, preloads \\ []) do
    case Repo.get(Contact, id) do
      nil -> {:error, :not_found}
      contact -> {:ok, Repo.preload(contact, preloads)}
    end
  end

  @doc """
  Vincula dois contatos bidirecionalmente.
  """
  def link_contact(default_contact_id, linked_contact_id) do
    existing =
      Repo.one(
        from(cl in ContactLink,
          where: cl.default_contact_id == ^default_contact_id and cl.linked_contact_id == ^linked_contact_id
        )
      )

    if existing do
      {:error, :already_linked}
    else
      # Via ida
      %ContactLink{}
      |> ContactLink.changeset(%{
        default_contact_id: default_contact_id,
        linked_contact_id: linked_contact_id
      })
      |> Repo.insert!()

      # Via volta (reverso)
      %ContactLink{}
      |> ContactLink.changeset(%{
        default_contact_id: linked_contact_id,
        linked_contact_id: default_contact_id
      })
      |> Repo.insert!()

      {:ok, :linked}
    end
  end


  @doc """
  Desvincula dois contatos bidirecionalmente.
  """
  def unlink_contact(nil, linked_contact_id) do
    ContactLink
    |> where([cl], cl.linked_contact_id == ^linked_contact_id)
    |> Repo.delete_all()
    |> case do
      {0, _} -> {:error, :not_found}
      {count, _} when count > 0 -> {:ok, count}
    end
  end
  def unlink_contact(default_contact_id, linked_contact_id) do
    # Remove via ida
    {fwd_count, _} =
      ContactLink
      |> where([cl], cl.default_contact_id == ^default_contact_id)
      |> where([cl], cl.linked_contact_id == ^linked_contact_id)
      |> Repo.delete_all()

    # Remove via volta (reverso)
    {rev_count, _} =
      ContactLink
      |> where([cl], cl.default_contact_id == ^linked_contact_id)
      |> where([cl], cl.linked_contact_id == ^default_contact_id)
      |> Repo.delete_all()

    total = fwd_count + rev_count

    case total do
      0 -> {:error, :not_found}
      count -> {:ok, count}
    end
  end


  @doc """
  Busca contato por nickname.
  """
  def find_contact_by_nickname(nickname) do
    case Repo.get_by(Contact, nickname: nickname) do
      nil -> {:error, :not_found}
      contact -> {:ok, contact}
    end
  end

  # --- Private ---

  defp apply_filters(query, params) do
    query
    |> maybe_filter_search(params)
    |> maybe_filter_online(params)
  end

  defp maybe_filter_search(query, %{search: search}) when is_binary(search) and search != "" do
    where(query, [c], ilike(c.name, ^"%#{search}%") or ilike(c.nickname, ^"%#{search}%"))
  end
  defp maybe_filter_search(query, %{"search" => search}) when is_binary(search) and search != "" do
    where(query, [c], ilike(c.name, ^"%#{search}%") or ilike(c.nickname, ^"%#{search}%"))
  end
  defp maybe_filter_search(query, _), do: query

  defp maybe_filter_online(query, %{is_online: is_online}) when is_boolean(is_online) do
    where(query, [c], c.is_online == ^is_online)
  end
  defp maybe_filter_online(query, %{"is_online" => is_online}) when is_boolean(is_online) do
    where(query, [c], c.is_online == ^is_online)
  end
  defp maybe_filter_online(query, _), do: query


  defp fetch_default_contact_id(params) do
    Map.get(params, :default_contact_id) || Map.get(params, "default_contact_id")
  end


  defp maybe_add_default_contact_where(query, nil), do: query
  defp maybe_add_default_contact_where(query, default_contact_id) do
    query
    |> where([c, cl], cl.default_contact_id == ^default_contact_id)
  end


  defp paginate(query, params) do
    page = parse_page(params)
    per_page = parse_per_page(params)
    offset = (page - 1) * per_page

    total = Repo.one!(from q in subquery(query |> distinct(true) |> select([c], c.id)), select: count(q.id))

    entries =
      query
      |> distinct(true)
      |> order_by([c], asc: c.name)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total: total,
      total_pages: calculate_total_pages(total, per_page),
      last_messages: %{}
    }
  end

  defp get_last_messages(user_id, contact_ids) when is_binary(user_id) and is_list(contact_ids) and contact_ids != [] do
    Message
    |> where([m],
      (m.contact_id == ^user_id and m.from_contact_id in ^contact_ids) or
      (m.contact_id in ^contact_ids and m.from_contact_id == ^user_id)
    )
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
    |> Enum.reduce(%{}, fn msg, acc ->
      other_party = if msg.contact_id == user_id, do: msg.from_contact_id, else: msg.contact_id
      if Map.has_key?(acc, other_party), do: acc, else: Map.put(acc, other_party, %{content: msg.content, timestamp: msg.inserted_at})
    end)
  end
  defp get_last_messages(_, _), do: %{}


  defp parse_page(%{page: page}) when is_integer(page) and page > 0, do: page
  defp parse_page(%{"page" => page}) when is_binary(page) do
    case Integer.parse(page) do
      {p, _} when p > 0 -> p
      _ -> 1
    end
  end
  defp parse_page(_), do: 1


  defp parse_per_page(%{per_page: per_page}) when is_integer(per_page) and per_page > 0 do
    min(per_page, @max_page_size)
  end
  defp parse_per_page(%{"per_page" => per_page}) when is_binary(per_page) do
    case Integer.parse(per_page) do
      {pp, _} when pp > 0 -> min(pp, @max_page_size)
      _ -> @default_page_size
    end
  end
  defp parse_per_page(_), do: @default_page_size


  defp calculate_total_pages(0, _), do: 0
  defp calculate_total_pages(total, per_page) do
    total
    |> div(per_page)
    |> then(&if rem(total, per_page) > 0, do: &1 + 1, else: &1)
  end
end
