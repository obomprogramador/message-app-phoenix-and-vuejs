defmodule MessageApp.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :nickname, :string, null: false
      add :avatar_url, :string
      add :is_online, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contacts, [:nickname])
    create index(:contacts, [:name])
    create index(:contacts, [:is_online])
  end
end
