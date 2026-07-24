defmodule MessageApp.Release do
  @moduledoc """
  Used for executing DB migrations and commands from a release,
  as well as running the app server.
  """

  def app, do: :message_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()
    priv_dir = Application.app_dir(:message_app, "priv")
    Path.join(priv_dir, "repo/seeds.exs") |> Code.eval_file()
  end

  defp repos do
    Application.fetch_env!(app(), :ecto_repos)
  end

  defp load_app do
    Application.load(app())
  end
end
