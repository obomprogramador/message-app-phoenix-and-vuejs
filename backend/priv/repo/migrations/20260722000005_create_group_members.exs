defmodule MessageApp.Repo.Migrations.CreateGroupMembers do
  use Ecto.Migration

  def change do
    create table(:group_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, default: "member"
      add :joined_at, :utc_datetime, default: fragment("NOW()")

      add :group_id,
          references(:groups, type: :binary_id, on_delete: :delete_all),
          null: false

      add :contact_id,
          references(:contacts, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:group_members, [:group_id])
    create index(:group_members, [:contact_id])
    create unique_index(:group_members, [:group_id, :contact_id])
  end
end
