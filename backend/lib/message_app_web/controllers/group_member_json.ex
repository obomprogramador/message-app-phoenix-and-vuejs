defmodule MessageAppWeb.GroupMemberJSON do
  def render("index.json", %{members: members}) do
    %{
      data: Enum.map(members.entries, &member_json/1),
      pagination: %{
        page: members.page,
        per_page: members.per_page,
        total: members.total,
        total_pages: members.total_pages
      }
    }
  end

  def render("show.json", %{member: member}) do
    %{data: member_json(member)}
  end

  defp member_json(%{__struct__: _} = member) do
    %{
      id: member.id,
      group_id: member.group_id,
      contact_id: member.contact_id,
      role: member.role,
      joined_at: member.joined_at
    }
  end

  defp member_json(member) do
    %{
      id: member[:id],
      group_id: member[:group_id],
      contact_id: member[:contact_id],
      role: member[:role],
      joined_at: member[:joined_at]
    }
  end
end
