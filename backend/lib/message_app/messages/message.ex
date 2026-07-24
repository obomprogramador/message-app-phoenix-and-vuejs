defmodule MessageApp.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :content, :string
    field :direction, :string
    field :is_read, :boolean, default: false

    belongs_to :contact, MessageApp.Contacts.Contact
    belongs_to :from_contact, MessageApp.Contacts.Contact

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :direction, :is_read, :contact_id, :from_contact_id])
    |> validate_required([:content, :direction, :contact_id])
    |> validate_inclusion(:direction, ["sent", "received"])
    |> foreign_key_constraint(:contact_id)
    |> foreign_key_constraint(:from_contact_id)
  end
end
