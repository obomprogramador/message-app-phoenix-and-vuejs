defmodule MessageApp.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "contacts" do
    field :name, :string
    field :nickname, :string
    field :avatar_url, :string
    field :is_online, :boolean, default: false

    has_many :messages, MessageApp.Messages.Message
    has_many :contact_links, MessageApp.Contacts.ContactLink, foreign_key: :default_contact_id
    has_many :linked_contacts, through: [:contact_links, :linked_contact]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :nickname, :avatar_url, :is_online])
    |> validate_required([:name, :nickname])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:nickname, min: 1, max: 255)
    |> unique_constraint(:nickname)
  end
end
