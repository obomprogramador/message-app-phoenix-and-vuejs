defmodule MessageApp.Repo.Migrations.AddFromContactIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :from_contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)
    end

    create index(:messages, [:from_contact_id])
  end
end
