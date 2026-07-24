defmodule MessageApp.Factory do
  @moduledoc """
  Factory for test fixtures using ExMachina.
  """

  use ExMachina.Ecto, repo: MessageApp.Repo

  def contact_factory do
    %MessageApp.Contacts.Contact{
      name: sequence(:name, &"Contato #{&1}"),
      nickname: sequence(:nickname, &"@contato.#{&1}"),
      avatar_url: nil,
      is_online: false
    }
  end

  def message_factory do
    %MessageApp.Messages.Message{
      content: sequence(:content, &"Mensagem #{&1}"),
      direction: "sent",
      is_read: false,
      contact: build(:contact)
    }
  end

  def group_factory do
    %MessageApp.Groups.Group{
      name: sequence(:group_name, &"Grupo #{&1}"),
      description: sequence(:group_desc, &"Descricao do grupo #{&1}"),
      avatar_url: nil,
      created_by: build(:contact)
    }
  end

  def group_member_factory do
    %MessageApp.Groups.GroupMember{
      role: "member",
      group: build(:group),
      contact: build(:contact)
    }
  end

  def group_message_factory do
    %MessageApp.Groups.GroupMessage{
      content: sequence(:group_msg, &"Mensagem do grupo #{&1}"),
      is_read: false,
      group: build(:group),
      sender: build(:contact)
    }
  end
end
