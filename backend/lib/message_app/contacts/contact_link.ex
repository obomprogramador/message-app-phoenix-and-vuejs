defmodule MessageApp.Contacts.ContactLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "contact_links" do
    field :linked_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second)

    belongs_to :default_contact, MessageApp.Contacts.Contact
    belongs_to :linked_contact, MessageApp.Contacts.Contact

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_link, attrs) do
    contact_link
    |> cast(attrs, [:default_contact_id, :linked_contact_id])
    |> validate_required([:default_contact_id, :linked_contact_id])
    |> foreign_key_constraint(:default_contact_id)
    |> foreign_key_constraint(:linked_contact_id)
    |> unique_constraint([:default_contact_id, :linked_contact_id])
  end
end
