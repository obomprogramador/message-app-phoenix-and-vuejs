defmodule MessageApp.Repo do
  use Ecto.Repo,
    otp_app: :message_app,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository configuration from the
  environment variable.
  """
  @impl true
  def init(_type, config) do
    config =
      config
      |> Keyword.put_new(:username, System.get_env("PGUSER"))
      |> Keyword.put_new(:password, System.get_env("PGPASSWORD"))
      |> Keyword.put_new(:hostname, System.get_env("PGHOST"))
      |> Keyword.put_new(
        :port,
        System.get_env("PGPORT") && String.to_integer(System.get_env("PGPORT"))
      )
      |> Keyword.put_new(:database, System.get_env("PGDATABASE"))
      |> Keyword.put_new(:pool_size, String.to_integer(System.get_env("POOL_SIZE") || "10"))

    {:ok, config}
  end
end
