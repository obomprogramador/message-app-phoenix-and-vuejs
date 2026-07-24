defmodule MessageApp.Repo.Migrations.CreateContactLinks do
  use Ecto.Migration

  def change do
    create table(:contact_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :linked_at, :utc_datetime, default: fragment("NOW()")

      add :default_contact_id,
          references(:contacts, type: :binary_id, on_delete: :delete_all),
          null: false

      add :linked_contact_id,
          references(:contacts, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:contact_links, [:default_contact_id])
    create index(:contact_links, [:linked_contact_id])

    create unique_index(:contact_links, [:default_contact_id, :linked_contact_id])
  end
end
