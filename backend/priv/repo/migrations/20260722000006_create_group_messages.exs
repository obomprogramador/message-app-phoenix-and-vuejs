defmodule MessageApp.Repo.Migrations.CreateGroupMessages do
  use Ecto.Migration

  def change do
    create table(:group_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :is_read, :boolean, default: false

      add :group_id,
          references(:groups, type: :binary_id, on_delete: :delete_all),
          null: false

      add :sender_id,
          references(:contacts, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:group_messages, [:group_id])
    create index(:group_messages, [:sender_id])
    create index(:group_messages, [:inserted_at])
  end
end
