defmodule MessageApp.Messages do
  @moduledoc """
  Contexto para gerenciamento de mensagens.
  """

  import Ecto.Query

  alias MessageApp.Repo
  alias MessageApp.Messages.Message

  @default_page_size 50
  @max_page_size 200

  @doc """
  Lista mensagens de uma conversa entre dois contatos.
  """
  def list_messages(contact_id, params \\ %{}) do
    current_user_id = params["current_user_id"]

    query =
      if current_user_id do
        # Retorna mensagens de ambos os lados da conversa
        Message
        |> where([m],
          (m.contact_id == ^contact_id and m.from_contact_id == ^current_user_id) or
            (m.contact_id == ^current_user_id and m.from_contact_id == ^contact_id)
        )
      else
        # Compatibilidade: retorna apenas mensagens do contact_id
        Message
        |> where([m], m.contact_id == ^contact_id)
      end

    result = query |> order_by([m], asc: m.inserted_at) |> paginate(params)

    if current_user_id do
      %{result | entries: Enum.map(result.entries, fn msg ->
        # Determina se a mensagem é do tipo sent ou received
        direction = if msg.from_contact_id == current_user_id, do: "sent", else: "received"
        # Atualiza o map advindo da pesquisa feita no DB.
        %{msg | direction: direction}
      end)}
    else
      result
    end
  end

  @doc """
  Envia uma mensagem.
  """
  def send_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marca mensagem como lida.
  """
  def mark_as_read(id) do
    case get_message(id) do
      {:ok, message} ->
        message
        |> Message.changeset(%{is_read: true})
        |> Repo.update()

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc """
  Busca mensagens por conteudo.
  """
  def search_messages(contact_id, query, params \\ %{}) do
    Message
    |> where([m], m.contact_id == ^contact_id)
    |> where([m], ilike(m.content, ^"%#{query}%"))
    |> order_by([m], desc: m.inserted_at)
    |> paginate(params)
  end

  # --- Private ---

  defp get_message(id) do
    case Repo.get(Message, id) do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end

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
