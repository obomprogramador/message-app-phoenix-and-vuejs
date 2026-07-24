defmodule MessageApp.Groups.GroupMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_members" do
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second)

    belongs_to :group, MessageApp.Groups.Group
    belongs_to :contact, MessageApp.Contacts.Contact

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group_member, attrs) do
    group_member
    |> cast(attrs, [:role, :group_id, :contact_id])
    |> validate_required([:group_id, :contact_id])
    |> validate_inclusion(:role, ["admin", "member"])
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:contact_id)
    |> unique_constraint([:group_id, :contact_id])
  end
end
