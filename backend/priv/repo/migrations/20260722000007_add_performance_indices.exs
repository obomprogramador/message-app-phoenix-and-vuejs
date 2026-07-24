defmodule MessageApp.Repo.Migrations.AddPerformanceIndices do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:messages, [:contact_id, :inserted_at])
    create_if_not_exists index(:group_messages, [:group_id, :inserted_at])
  end
end
