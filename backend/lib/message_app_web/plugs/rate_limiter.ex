defmodule MessageAppWeb.Plugs.RateLimiter do
  @moduledoc """
  Plug de rate limiting usando ExRated (sliding window counter).

  Opcoes:
    - `:limit` — numero maximo de requisicoes por janela (default: 100)
    - `:period` — duracao da janela em segundos (default: 60)
    - `:key` — funcao para gerar a chave do cliente (default: por IP)
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    limit = Keyword.get(opts, :limit, 100)
    period = Keyword.get(opts, :period, 60)
    key = build_key(conn, opts)

    case ExRated.check_rate(key, period, limit) do
      {:ok, _count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(max(limit - get_count(key, period), 0)))

      {:error, _limit} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{errors: %{detail: "Rate limit exceeded"}}))
        |> halt()
    end
  end

  defp build_key(conn, opts) do
    custom_key = Keyword.get(opts, :key)

    case custom_key do
      fun when is_function(fun, 1) -> to_string(fun.(conn))
      _ -> client_ip(conn)
    end
  end

  defp client_ip(conn) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp get_count(key, period) do
    case ExRated.inspect_bucket(key, period, 100) do
      {:ok, {count, _, _, _, _}} -> count
      _ -> 0
    end
  end
end
