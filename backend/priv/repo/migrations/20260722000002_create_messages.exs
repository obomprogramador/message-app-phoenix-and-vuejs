defmodule MessageApp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :direction, :string, null: false
      add :is_read, :boolean, default: false

      add :contact_id,
          references(:contacts, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:contact_id])
    create index(:messages, [:inserted_at])
    create index(:messages, [:direction])
  end
end
