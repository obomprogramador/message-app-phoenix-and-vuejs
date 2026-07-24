defmodule MessageApp.Groups.GroupMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_messages" do
    field :content, :string
    field :is_read, :boolean, default: false

    belongs_to :group, MessageApp.Groups.Group
    belongs_to :sender, MessageApp.Contacts.Contact

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group_message, attrs) do
    group_message
    |> cast(attrs, [:content, :is_read, :group_id, :sender_id])
    |> validate_required([:content, :group_id, :sender_id])
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:sender_id)
  end
end
