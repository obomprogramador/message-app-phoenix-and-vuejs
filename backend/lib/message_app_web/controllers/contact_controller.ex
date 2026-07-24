defmodule MessageAppWeb.ContactController do
  use MessageAppWeb, :controller

  alias MessageApp.Contacts

  action_fallback MessageAppWeb.FallbackController

  def index(conn, params) do
    contacts = Contacts.list_contacts(params)
    render(conn, :index, contacts: contacts)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, contact} <- Contacts.get_contact(id) do
      render(conn, :show, contact: contact)
    end
  end

  def create(conn, %{"contact" => %{"nickname" => nickname}} = params) do
    default_contact_id = params["default_contact_id"]

    with {:ok, linked_contact} <- Contacts.find_contact_by_nickname(nickname),
         {:ok, _link} <- Contacts.link_contact(default_contact_id, linked_contact.id) do
      conn
      |> put_status(:created)
      |> render(:show, contact: linked_contact)
    end
  end

  def create(conn, %{"contact" => %{"linked_contact_id" => linked_contact_id}} = params) do
    default_contact_id = params["default_contact_id"]

    with {:ok, linked_contact} <- Contacts.get_contact(linked_contact_id),
         {:ok, _link} <- Contacts.link_contact(default_contact_id, linked_contact.id) do
      conn
      |> put_status(:created)
      |> render(:show, contact: linked_contact)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    default_contact_id = params["default_contact_id"]

    with {:ok, _} <- Contacts.unlink_contact(default_contact_id, id) do
      send_resp(conn, :no_content, "")
    end
  end
end
