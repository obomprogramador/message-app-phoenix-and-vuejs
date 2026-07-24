defmodule MessageApp.Groups.Group do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :description, :string
    field :avatar_url, :string

    belongs_to :created_by, MessageApp.Contacts.Contact, source: :created_by
    has_many :group_members, MessageApp.Groups.GroupMember
    has_many :members, through: [:group_members, :contact]
    has_many :group_messages, MessageApp.Groups.GroupMessage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description, :avatar_url, :created_by_id])
    |> validate_required([:name, :created_by_id])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:created_by_id)
  end
end
